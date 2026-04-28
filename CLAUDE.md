# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mahdavia Data Management System (MDMS) — Azure cloud infrastructure managed with Terraform. State is stored in Terraform Cloud (`noormahdi` org, workspaces `core-dev` and `core-prod`).

## Common Commands

```bash
# Validate formatting (mirrors CI check)
terraform fmt -check -recursive infra/

# Fix formatting
terraform fmt -recursive infra/

# Work on an environment
cd infra/environments/dev   # or prod
terraform init
terraform plan
terraform apply
```

## Architecture

### Terraform Structure

- `infra/modules/entra/` — Reusable module that looks up an existing **Entra External ID (CIAM)** directory using `azapi` and reads its tenant ID. It does not create the directory — it's a data-only module.
- `infra/environments/dev/` — Instantiates the `entra` module for dev (`mahdavisonlinedev.onmicrosoft.com`, RG `rg-mdms-dev-si-01`). TFC workspace: `core-dev`.
- `infra/environments/prod/` — Same pattern for prod (`mahdavisonline.onmicrosoft.com`, RG `rg-mdms-prod-si-01`). TFC workspace: `core-prod`.

### Providers

| Provider | Version | Purpose |
|---|---|---|
| `hashicorp/azurerm` | `~> 3.110` | Core Azure resources |
| `azure/azapi` | `~> 1.15` | Entra External ID CIAM directory lookup |

### CI/CD (`.github/workflows/main.yml`)

- **Validate** job: runs `terraform fmt -check -recursive infra/` on every push/dispatch.
- **Deploy dev**: runs automatically after validate passes; no approval required.
- **Deploy prod**: only runs on manual dispatch with `deploy_prod = true`; requires reviewer approval via the `prod` GitHub Environment.
- Authentication to Azure uses **OIDC federated credentials** — no client secret. The `ARM_USE_OIDC=true` env var enables this. `ARM_SUBSCRIPTION_ID` and `TF_VAR_subscription_id` are injected per environment job.

### Custom Branding (`infra/modules/entra/branding.tf`)

Applies Mahdavis Online brand to each CIAM tenant via Microsoft Graph API using a `terraform_data` resource (there is no ARM or `azuread` Terraform resource for CIAM branding).

- **CSS**: `infra/modules/entra/css/custom.css` — colors `#0F3D2E` / `#1F7A5C` / `#C9A24A`, Segoe UI, uploaded as binary to `PUT .../branding/localizations/0/customCSS`.
- **Images**: Drop files in `infra/modules/entra/assets/` — `background.jpg`, `banner-logo.png` (245×36), `square-logo.jpg` (240×240), `favicon.ico` (32×32). Upload is skipped when a file is absent.
- **Text**: `branding_sign_in_text` variable (default: "Secure access for Mahdavia community applications").
- **Script**: `infra/modules/entra/scripts/apply-branding.ps1` — PowerShell script invoked via `pwsh -File`; reads all config from environment variables set by `local-exec`.
- **Triggers**: Re-runs on CSS content change, script content change, text change, or tenant ID change.
- **Requires** `pwsh` (PowerShell 7+, present on `ubuntu-latest`).

**One-time CIAM tenant setup** (per environment):
1. Create an app registration *inside* the CIAM tenant (not the home tenant).
2. Grant `Organization.ReadWrite.All` application permission and admin-consent it.
3. Create a client secret.
4. Add `CIAM_CLIENT_ID` and `CIAM_CLIENT_SECRET` as secrets on the corresponding GitHub Environment (`dev` / `prod`). The workflow uses environment-level secrets so each environment automatically gets its own CIAM credentials.

### Key Constraints

- Terraform Cloud workspaces must be set to **Local** execution mode (the pipeline runs Terraform locally against TFC for state only).
- The `entra` module expects the Entra External ID (CIAM) directory to already exist — it only reads it via `azapi_resource` data source, not creates it.
- All resource groups are in the **South India** region.
