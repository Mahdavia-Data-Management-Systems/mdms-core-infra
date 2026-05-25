# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mahdavia Data Management System (MDMS) — Azure cloud infrastructure managed with Terraform. State is stored in Terraform Cloud (`noormahdi` org, workspaces `core-dev`, `core-prod`, `apps-dev`, `apps-prod`).

## Common Commands

```bash
# Validate formatting (mirrors CI check)
terraform fmt -check -recursive infra/

# Fix formatting
terraform fmt -recursive infra/

# Work on core CIAM tenant config
cd infra/environments/dev/core   # or prod/core
terraform init
terraform plan
terraform apply

# Work on app registrations
cd infra/environments/dev/apps   # or prod/apps
terraform init
terraform plan
terraform apply
```

## Architecture

### Terraform Structure

- `infra/modules/entra/` — Reusable module that looks up an existing **Entra External ID (CIAM)** directory using `azapi` and reads its tenant ID. Also applies custom branding and social identity providers. It does not create the directory — it's a data-only module for the directory itself.
- `infra/modules/entra-app/` — Provisions app registrations inside a CIAM tenant via Microsoft Graph API. Full lifecycle: creates on `apply`, deletes on `destroy`. Supports `spa` and `web` app types.
- `infra/modules/entra-user-flow/` — Placeholder module; not yet implemented.
- `infra/environments/dev/core/` — Instantiates the `entra` module for dev (`mahdavisonlinedev.onmicrosoft.com`, RG `rg-mdms-dev-si-01`). TFC workspace: `core-dev`.
- `infra/environments/dev/apps/` — Instantiates `entra-app` for each entry in `apps.yaml`. TFC workspace: `apps-dev`.
- `infra/environments/prod/core/` — Same pattern as dev core for prod (`mahdavisonline.onmicrosoft.com`, RG `rg-mdms-prod-si-01`). TFC workspace: `core-prod`.
- `infra/environments/prod/apps/` — Same pattern as dev apps for prod. TFC workspace: `apps-prod`.

### Providers

| Provider | Version | Purpose |
|---|---|---|
| `hashicorp/azurerm` | `~> 3.110` | Core Azure resources |
| `azure/azapi` | `~> 1.15` | Entra External ID CIAM directory lookup |
| `hashicorp/external` | `~> 2.3` | Query app details after creation (entra-app module) |

### CI/CD

Three workflows:

- **`.github/workflows/main.yml`** — Core pipeline for CIAM tenant config (branding, social IDPs). Runs on push to `main` (excluding `infra/environments/*/apps/**`) and manual dispatch.
  - **Validate** job: runs `terraform fmt -check -recursive infra/` on every trigger.
  - **Deploy dev** (`infra/environments/dev/core`): runs automatically after validate.
  - **Deploy prod** (`infra/environments/prod/core`): only on manual dispatch with `deploy_prod = true`; requires reviewer approval via the `prod` GitHub Environment.

- **`.github/workflows/apps-dev.yml`** — App registrations for dev. Triggered on push touching `infra/environments/dev/apps/**` or manual dispatch. Runs validate → deploy (`infra/environments/dev/apps`).

- **`.github/workflows/apps-prod.yml`** — App registrations for prod. Same pattern, requires prod approval.

Authentication to Azure uses **OIDC federated credentials** — no client secret. The `ARM_USE_OIDC=true` env var enables this. `ARM_SUBSCRIPTION_ID` and `TF_VAR_subscription_id` are injected per environment job.

### Custom Branding (`infra/modules/entra/branding.tf`)

Applies Mahdavis Online brand to each CIAM tenant via Microsoft Graph API using a `terraform_data` resource (there is no ARM or `azuread` Terraform resource for CIAM branding).

- **CSS**: `infra/modules/entra/css/custom.css` — colors `#0F3D2E` / `#1F7A5C` / `#C9A24A`, Segoe UI, uploaded as binary to `PUT .../branding/localizations/0/customCSS`.
- **Images**: Drop files in `infra/modules/entra/assets/` — `background.jpg`, `banner-logo.png` (245×36), `square-logo.jpg` (240×240), `favicon.ico` (32×32). Upload is skipped when a file is absent.
- **Text**: `branding_sign_in_text` variable (default: "One Identity. One Community. Endless Access.").
- **Script**: `infra/modules/entra/scripts/apply-branding.ps1` — PowerShell script invoked via `pwsh -File`; reads all config from environment variables set by `local-exec`.
- **Triggers**: Re-runs on CSS content change, script content change, text change, or tenant ID change.
- **Requires** `pwsh` (PowerShell 7+, present on `ubuntu-latest`).

### Social Identity Providers (`infra/modules/entra/google-idp.tf`, `facebook-idp.tf`)

Registers Google and Facebook as social IDPs via Microsoft Graph API.

- Uses `count = var.<provider>_client_id != null ? 1 : 0` — resource is skipped when credentials not provided.
- Scripts: `apply-google-idp.ps1`, `apply-facebook-idp.ps1` (shared helpers in `idp-helpers.ps1`).
- Required CIAM permission: `IdentityProvider.ReadWrite.All`.

### App Registrations (`infra/modules/entra-app/`)

Provisions app registrations and service principals in a CIAM tenant.

- App definitions live in `apps.yaml` (per environment). Terraform reads the YAML and iterates with `for_each`.
- `app_type: spa` → uses `spa.redirectUris`; `app_type: web` → uses `web.redirectUris` + optional `logoutUrl`.
- Both types enable implicit grant (ID token + access token).
- `get-app.ps1` retries up to 10 times (6 s delay) to handle Graph API eventual consistency.
- Lifecycle: `apply-app.ps1` creates/updates; `delete-app.ps1` deletes on `terraform destroy`.
- Required CIAM permission: `Application.ReadWrite.All`.

**One-time CIAM tenant setup** (per environment):
1. Create an app registration *inside* the CIAM tenant (not the home tenant).
2. Grant these application permissions and admin-consent them:
   - `Organization.ReadWrite.All` (branding)
   - `Application.ReadWrite.All` (app registrations)
   - `IdentityProvider.ReadWrite.All` (social IDPs)
3. Create a client secret.
4. Add `CIAM_CLIENT_ID` and `CIAM_CLIENT_SECRET` as secrets on the corresponding GitHub Environment (`dev` / `prod`). The workflow uses environment-level secrets so each environment automatically gets its own CIAM credentials.

### Key Constraints

- Terraform Cloud workspaces must be set to **Local** execution mode (the pipeline runs Terraform locally against TFC for state only).
- The `entra` module expects the Entra External ID (CIAM) directory to already exist — it only reads it via `azapi_resource` data source, not creates it.
- All resource groups are in the **South India** region.
- `entra-user-flow` module and `user-flows` environments are placeholders with no implementation yet.
