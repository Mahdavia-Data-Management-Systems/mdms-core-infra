# Repository Hardening Plan — mdms-core-infra

This repository is public, every deploy job runs `terraform apply -auto-approve`, and the apply
executes PowerShell scripts from the repository against the Entra CIAM tenant with client secrets
in the process environment. Nothing currently stands between a push and that apply. This plan
brings the repository up to the baseline already applied to `ishqnama-web` (recorded in that
repository's `infra/README.md` under **Repository protection**).

`$R` below is `Mahdavia-Data-Management-Systems/mdms-core-infra`. None of these settings live in
Terraform; they are GitHub settings, recorded here so they can be recreated.

## Current state

| Control | ishqnama-web | mdms-core-infra |
| --- | --- | --- |
| Deployment branch policy (environment restricted to `main`) | yes | **none — any branch** |
| Required reviewer on `prod` | yes | yes (already correct) |
| Ruleset on `main` (PR + approval, no force-push or deletion) | yes | **none** |
| `.github/CODEOWNERS` | yes | **none** |
| Actions allowlist | selected | **all actions allowed** |
| Fork PR approval policy | `all_external_contributors` | `first_time_contributors` |
| PR validation workflow | yes | **none** |
| Dependabot | yes | **none** |
| Default `GITHUB_TOKEN` permissions | read | read (already correct) |
| Every apply runs inside an environment | yes | yes (already correct) |

## Why this repository carries the most risk in the organisation

It is the identity root of trust. It manages the Entra External ID (CIAM) tenant — branding, the
Google and Facebook identity providers, and the application registrations. `ishqnama-web`'s
production configuration reads this tenant from the `core-prod` Terraform Cloud workspace through
its `mdms_core_workspace` variable. A bad apply here does not just affect this repository; it can
break sign-in for every application in the organisation.

Two properties make the exposure larger than it first appears:

- **The apply executes repository code.** `infra/modules/entra/*.tf` and
  `infra/modules/entra-app/main.tf` use `local-exec` provisioners and a `data "external"` source
  that run `pwsh` scripts from the repository, with `CIAM_CLIENT_SECRET`, `GOOGLE_CLIENT_SECRET`
  and `FACEBOOK_CLIENT_SECRET` passed in the provisioner environment. Whoever can change a file in
  this repository can therefore execute arbitrary code with those secrets available. That makes
  item 2 below considerably more serious than it would be for a repository whose Terraform only
  calls providers.
- **Steady-state Azure cost is near zero, so the bill risk is entirely the token path.** This
  repository provisions no billable Azure compute. The exposure is that a job here can mint an
  Azure OIDC token for the subscription, and anything holding that token can create any resource
  in it.

## Findings, in order of blast radius

### 1. No deployment branch policies, so any ref can obtain Azure credentials

Neither `dev` nor `prod` has a deployment branch policy, so both accept deployments from any
branch. Because the federated credential subject is `...:environment:<env>`, an environment with
no branch policy means any branch can mint an Azure token. `main.yml` also exposes
`workflow_dispatch`, and a dispatch can be run from any branch.

The required reviewer on `prod` does **not** close this. It gates the production job specifically;
`dev` has no protection rules at all, so a dispatch from an arbitrary branch reaches the `dev` job,
obtains Azure credentials, and runs the repository's PowerShell scripts against the dev CIAM
tenant with the dev secrets in the environment. This is the most important gap in the repository.

### 2. `main` is unprotected

There is no ruleset and no branch protection. Direct pushes, force-pushes and branch deletion are
all permitted, and there are no required status checks or reviews. Given that an apply executes
repository code (above), an unprotected `main` is the highest-leverage weakness here.

### 3. All actions are allowed

`allowed_actions` is `all`, so any third-party action can run inside a job that holds the Azure
OIDC token, the Terraform Cloud token, and the CIAM, Google and Facebook client secrets.

### 4. No pull request validation

There is no `pull_request` workflow, so there is nothing to require as a status check once rulesets
are enabled. The `validate` job in `main.yml` runs only after a push has already landed on `main`,
which is too late to prevent anything.

### 5. `main.yml` chains production directly onto development

`deploy-prod` declares `needs: deploy-dev`, so every push to `main` queues a production apply. The
required reviewer means it waits rather than applies, which is the correct behaviour, but it does
mean routine pushes generate pending production deployments that must be dismissed.

### 6. Minor items

- The `github-pages` environment exists with a branch policy but appears unused. If nothing
  deploys Pages, remove it so it cannot be used as an unreviewed path.
- `apps-dev.yml` and `apps-prod.yml` are disabled with `on: []` and a comment that the apps are
  managed by hand in the Azure portal. They still carry full deploy logic and can be re-enabled by
  a one-line push. Consider deleting them; the git history retains them if needed.

## Planned changes

### Step 0 (DONE) — Stop the ungated `validate` job from seeing the Terraform Cloud token

Cheap, self-contained, and independent of every GitHub setting below, so it can go in first.

`main.yml` sets the token in the workflow-level `env:` block, which applies to *every* job:

```yaml
env:
  ARM_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
  ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
  ARM_USE_OIDC: "true"
  TF_TOKEN_app_terraform_io: ${{ secrets.TF_API_TOKEN }}   # <- every job, including validate

jobs:
  validate:          # declares no environment, so no branch policy and no reviewer
```

`validate` declares no environment, so the one job with no gate of any kind is handed the
Terraform Cloud token. That token reads workspace state, and state stores resource attributes in
plaintext, so it is effectively a credential dump — and quieter than an apply, because it changes
nothing.

Move `TF_TOKEN_app_terraform_io` out of the workflow-level `env:` and into the `deploy-dev` and
`deploy-prod` job `env:` blocks, which already declare `environment: dev` and `environment: prod`.
`validate` only runs `terraform fmt -check -recursive`, which needs no token, so nothing breaks.

The same reasoning applies to `ARM_CLIENT_ID` and `ARM_TENANT_ID`, though those are `vars` rather
than secrets and are far less sensitive; moving them down alongside the token keeps the workflow
consistent.

### Step 1 (DONE) — Restrict both environments to `main`

This is the single highest-value change. Apply before anything else.

```bash
R=Mahdavia-Data-Management-Systems/mdms-core-infra
gh api -X PUT "repos/$R/environments/dev" --input - <<'JSON'
{"deployment_branch_policy":{"protected_branches":false,"custom_branch_policies":true}}
JSON
gh api -X POST "repos/$R/environments/dev/deployment-branch-policies" -f name=main -f type=branch
```

For `prod`, the existing required reviewer must be re-sent in the same call, because a `PUT`
replaces an environment's protection rules and would otherwise wipe it silently:

```bash
gh api -X PUT "repos/$R/environments/prod" --input - <<'JSON'
{"reviewers":[{"type":"User","id":<noormahdi-user-id>}],
 "prevent_self_review":false,
 "deployment_branch_policy":{"protected_branches":false,"custom_branch_policies":true}}
JSON
gh api -X POST "repos/$R/environments/prod/deployment-branch-policies" -f name=main -f type=branch
```

Resolve the id with `gh api users/noormahdi --jq .id`, and confirm the reviewer survived with
`gh api "repos/$R/environments/prod" --jq '.protection_rules'`.

### Step 2 — Add a ruleset on `main`

Require a pull request with one approval, require the PR validation checks from step 4, require
code owner review, and block deletion and force-push. The sole maintainer needs to be a bypass
actor, because GitHub will not accept a pull request author's own approval; the deployment branch
policies from step 1 still apply to whatever is merged.

Given that an apply here executes repository PowerShell, this step is worth more in this
repository than in any other in the organisation.

### Step 3 — Restrict the actions allowlist

The only actions used are `actions/checkout` and `hashicorp/setup-terraform`.

```bash
gh api -X PUT "repos/$R/actions/permissions" -F enabled=true -f allowed_actions=selected
gh api -X PUT "repos/$R/actions/permissions/selected-actions" --input - <<'JSON'
{"github_owned_allowed":true,"verified_allowed":false,
 "patterns_allowed":["hashicorp/setup-terraform@*"]}
JSON
```

### Step 4 — Add `pr-validation.yml`

Triggered by `pull_request` into `main`, never `pull_request_target`; `contents: read`; no
environment and no secrets, so a fork pull request cannot deploy. It should run
`terraform fmt -check -recursive infra/`, which is what `main.yml`'s `validate` job already does,
only at a point where it can still prevent a merge.

`terraform validate` is deliberately excluded: it needs `terraform init`, and the `cloud {}` block
requires the Terraform Cloud token, which must not be exposed to a fork.

### Step 5 — Tighten fork pull request approval

```bash
gh api -X PUT "repos/$R/actions/permissions/fork-pr-contributor-approval" \
  -f approval_policy=all_external_contributors
```

### Step 6 — Add `.github/CODEOWNERS`

```
# Everything that can deploy or touch the CIAM tenant needs the owner's review.
/.github/  @noormahdi
/infra/    @noormahdi
```

### Step 7 — Add `.github/dependabot.yml`

Cover `github-actions` and `terraform`. Group the GitHub Actions updates into a single weekly pull
request rather than one per action.

### Step 8 — Clean up the unused surface

Remove the `github-pages` environment if nothing deploys Pages, and delete `apps-dev.yml` and
`apps-prod.yml` if the apps are to stay manually managed.

## Open question

**Confirmed 2026-09-14:** the organisation secrets are `TF_API_TOKEN`, `DOCKERHUB_TOKEN` and
`CLOUDFLARE_API_TOKEN`, and all three are set to `visibility=all`. The organisation variables
`AZURE_CLIENT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`, `CLOUDFLARE_ACCOUNT_ID` and
`DOCKERHUB_USERNAME` are likewise `visibility=all`. Every repository in the organisation can
therefore read all of them, including the private `ishqnama-db` and any repository created in
future. This is the widest possible setting, so the concern below is real rather than theoretical.

Whether `TF_API_TOKEN` should be recreated as an environment secret on `dev` and `prod` rather than
organisation-level, so it sits behind the branch policies from step 1. The CIAM, Google and
Facebook secrets are already correctly scoped as environment secrets on `dev` and `prod` in this
repository. Changing `TF_API_TOKEN` needs org-admin rights and affects the other repositories, so
it should be decided across all of them at once rather than here.

Note the ordering dependency. Moving the token to environment secrets buys little on its own: any
workflow can simply declare `environment: dev` and receive it again. The gain comes from the fact
that declaring an environment subjects the job to that environment's protection rules, so the
value only materialises once step 1 is in place. Environment secrets are a multiplier on the
branch policies, not a substitute for them. Step 0 is the cheap interim mitigation that closes the
specific `validate` hole without waiting for any of this.
