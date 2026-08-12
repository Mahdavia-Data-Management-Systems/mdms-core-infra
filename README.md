# Mahdavia Data Management System (MDMS)

Cloud infrastructure and data management platform for Mahdavia, built on Azure with infrastructure managed via Terraform.

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── main.yml           # Core CI/CD pipeline (CIAM tenants)
│       ├── apps-dev.yml       # Dev app registrations pipeline
│       └── apps-prod.yml      # Prod app registrations pipeline
├── assets/                    # Brand source assets (logos, favicon)
└── infra/
    ├── modules/
    │   ├── entra/             # Entra External ID (CIAM) tenant module
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── outputs.tf
    │   │   ├── versions.tf
    │   │   ├── branding.tf    # Custom branding via Microsoft Graph API
    │   │   ├── google-idp.tf  # Google social identity provider
    │   │   ├── facebook-idp.tf # Facebook social identity provider
    │   │   ├── assets/        # banner-logo.png, square-logo.jpg, favicon.ico
    │   │   ├── css/           # custom.css for sign-in page
    │   │   └── scripts/       # apply-branding.ps1, apply-google-idp.ps1, apply-facebook-idp.ps1, idp-helpers.ps1
    │   ├── entra-app/         # App registration provisioning module
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── outputs.tf
    │   │   ├── versions.tf
    │   │   └── scripts/       # apply-app.ps1, delete-app.ps1, get-app.ps1, app-helpers.ps1
    └── environments/
        ├── dev/
        │   ├── core/          # CIAM tenant config — TFC workspace: core-dev
        │   └── apps/          # App registrations — TFC workspace: apps-dev
        └── prod/
            ├── core/          # CIAM tenant config — TFC workspace: core-prod
            └── apps/          # App registrations — TFC workspace: apps-prod
```

## Prerequisites

### Tools

| Tool | Version | Install |
|---|---|---|
| Terraform | >= 1.7 | https://developer.hashicorp.com/terraform/install |
| Azure CLI | Latest | https://learn.microsoft.com/en-us/cli/azure/install-azure-cli |
| PowerShell | 7+ (`pwsh`) | https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell |

### Terraform Cloud

1. Create an account at https://app.terraform.io
2. Create an organization named `MDMS`
3. Create four workspaces: `core-dev`, `core-prod`, `apps-dev`, `apps-prod`
4. Set **Execution Mode** to **Local** on all four workspaces
5. Generate an API token: **User Settings → Tokens → Create an API token**

### Azure — Service Principal

Create a service principal for GitHub Actions to authenticate with Azure:

```bash
az ad sp create-for-rbac --name "sp-mdms-github" --skip-assignment
```

Note the `appId`, `tenant` values from the output.

#### Role assignments

Assign the following on the subscription (**Portal → Subscriptions → Access control (IAM) → Add role assignment**):

| Role | Scope | Purpose |
|---|---|---|
| `Contributor` | Subscription | Create and manage Azure resources |

#### Federated credentials (OIDC)

No client secret is used. Configure federated credentials on the service principal so GitHub Actions can authenticate via OIDC.

In **Portal → Microsoft Entra ID → App registrations → sp-mdms-github → Certificates & secrets → Federated credentials**, add:

| Field | Value |
|---|---|
| Issuer | `https://token.actions.githubusercontent.com` |
| Subject | `repo:<org>/<repo>:environment:dev` |
| Audience | `api://AzureADTokenExchange` |

Add a second credential for prod:

| Field | Value |
|---|---|
| Issuer | `https://token.actions.githubusercontent.com` |
| Subject | `repo:<org>/<repo>:environment:prod` |
| Audience | `api://AzureADTokenExchange` |

### GitHub — Secrets

#### Organization secrets

Set at **GitHub org → Settings → Secrets and variables → Actions → Secrets**:

| Secret | Description |
|---|---|
| `TF_API_TOKEN` | Terraform Cloud API token |

#### Environment secrets (`dev` and `prod`)

Set at **GitHub repo → Settings → Environments → (dev \| prod) → Environment secrets**:

| Secret | Description |
|---|---|
| `CIAM_CLIENT_SECRET` | Client secret for the CIAM tenant app registration |
| `GOOGLE_CLIENT_SECRET` | Google OAuth2 client secret |
| `FACEBOOK_CLIENT_SECRET` | Facebook OAuth2 client secret |

### GitHub — Variables

#### Organization variables

Set at **GitHub org → Settings → Secrets and variables → Actions → Variables**:

| Variable | Description |
|---|---|
| `AZURE_CLIENT_ID` | Service principal app (client) ID |
| `AZURE_TENANT_ID` | Home Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

#### Environment variables (`dev` and `prod`)

Set at **GitHub repo → Settings → Environments → (dev \| prod) → Environment variables**:

| Variable | Description |
|---|---|
| `CIAM_CLIENT_ID` | App registration client ID from inside the CIAM tenant |
| `GOOGLE_CLIENT_ID` | Google OAuth2 client ID (optional — IDP skipped if absent) |
| `FACEBOOK_CLIENT_ID` | Facebook OAuth2 client ID (optional — IDP skipped if absent) |

### GitHub — Environments

Create two environments at **GitHub repo → Settings → Environments**:

| Environment | Protection rule |
|---|---|
| `dev` | None — deploys automatically |
| `prod` | **Required reviewers** — add yourself to gate prod deployments |

See [`infra/README.md`](infra/README.md) for the one-time CIAM tenant setup steps.

## CI/CD Pipelines

### Core pipeline (`main.yml`)

Manages CIAM tenant configuration (branding, social IDPs).

Triggers:
- **Push to `main`** (excluding `infra/environments/*/apps/**`) — validates and deploys to dev automatically
- **Manual dispatch** — deploys to both dev and prod (prod requires reviewer approval)

| Stage | Runs when | Approval required |
|---|---|---|
| Validate | Every trigger | No |
| Deploy (dev) | After validate passes | No |
| Deploy (prod) | Manual dispatch, after dev succeeds | Yes |

### Apps pipelines (`apps-dev.yml` / `apps-prod.yml`)

Manage app registrations defined in `apps.yaml`.

| Pipeline | Trigger | Working directory |
|---|---|---|
| `apps-dev.yml` | Push to `main` touching `infra/environments/dev/apps/**`, or manual dispatch | `infra/environments/dev/apps` |
| `apps-prod.yml` | Push to `main` touching `infra/environments/prod/apps/**`, or manual dispatch | `infra/environments/prod/apps` |

## App Registrations

App registrations are declared in `apps.yaml` per environment. Terraform reads the YAML and provisions each app via the `entra-app` module using Microsoft Graph API.

**Example `apps.yaml`:**

```yaml
apps:
  - name: sample-app
    display_name: "Sample App"
    app_type: web          # "spa" (public, PKCE) or "web" (confidential)
    redirect_uris:
      - https://example.com/callback
    logout_url: https://example.com/signout
```

To add an app, add an entry to `infra/environments/<env>/apps/apps.yaml` and push to `main`.

## Infrastructure

See [`infra/README.md`](infra/README.md) for full details on the Terraform module structure, environments, and resource configurations.
