# Infrastructure as Code

Manages cloud infrastructure using Terraform. State is stored in Terraform Cloud under the `noormahdi` organization.

## Structure

```
infra/
├── modules/
│   └── entra/                # Entra External ID (CIAM) tenant module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── branding.tf       # Custom branding via Microsoft Graph API
│       ├── assets/           # background.jpg, banner-logo.png, square-logo.jpg, favicon.ico
│       ├── css/
│       │   └── custom.css    # Sign-in page styles
│       └── scripts/
│           └── apply-branding.ps1
└── environments/
    ├── dev/                  # TFC workspace: core-dev
    │   ├── versions.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── prod/                 # TFC workspace: core-prod
        ├── versions.tf
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Environments

| Environment | Resource Group | Entra Domain | TFC Workspace |
|---|---|---|---|
| dev | rg-mdms-dev-si-01 | mahdavisonlinedev.onmicrosoft.com | core-dev |
| prod | rg-mdms-prod-si-01 | mahdavisonline.onmicrosoft.com | core-prod |

All resource groups are located in **South India**.

## Providers

| Provider | Source | Purpose |
|---|---|---|
| `azurerm` | `hashicorp/azurerm ~> 3.110` | Core Azure resource management |
| `azapi` | `azure/azapi ~> 1.15` | Entra External ID (CIAM) directory lookup |

## Custom Branding

`branding.tf` applies the Mahdavis Online brand to each CIAM tenant's sign-in page via Microsoft Graph API using a `terraform_data` resource with a `local-exec` provisioner.

- **CSS**: `css/custom.css` — colors `#0F3D2E` / `#1F7A5C` / `#C9A24A`, Segoe UI
- **Images**: Place files in `assets/` — upload is skipped if a file is absent

| File | Dimensions |
|---|---|
| `background.jpg` | Recommended 1920×1080 |
| `banner-logo.png` | 245×36 |
| `square-logo.jpg` | 240×240 |
| `favicon.ico` | 32×32 |

- **Script**: `scripts/apply-branding.ps1` — reads config from environment variables; requires `pwsh` (PowerShell 7+)
- **Triggers**: Re-runs when CSS content, script content, sign-in text, or tenant ID changes

### One-time CIAM tenant setup (per environment)

1. Create an app registration **inside** the CIAM tenant (not the home tenant).
2. Grant `Organization.ReadWrite.All` application permission and admin-consent it.
3. Create a client secret.
4. Add `CIAM_CLIENT_ID` and `CIAM_CLIENT_SECRET` as secrets on the corresponding GitHub Environment (`dev` / `prod`).

## CI/CD Pipeline

The pipeline (`.github/workflows/main.yml`) triggers on:
- **Push to `main`** — automatically validates and deploys to dev
- **Manual dispatch** — same as above, with an optional **Deploy to production** toggle

### Pipeline stages

| Stage | Trigger | Manual approval |
|---|---|---|
| Validate | Always | No |
| Deploy (dev) | Always, after validate | No |
| Deploy (prod) | Manual dispatch with `deploy_prod = true`, after dev succeeds | Yes — configured on the `prod` GitHub Environment |

### Azure authentication

GitHub authenticates to Azure via **federated credentials (OIDC)** — no client secret required.

## Prerequisites

- Terraform >= 1.7
- PowerShell 7+ (`pwsh`) — for branding provisioner
- Terraform Cloud account in the `noormahdi` organization with workspaces `core-dev` and `core-prod` set to **Local** execution mode
- Azure service principal with `Contributor` role, configured with a federated credential for this repository

## Required GitHub Secrets

### Repository-level

| Secret | Description |
|---|---|
| `TF_API_TOKEN` | Terraform Cloud API token |
| `AZURE_CLIENT_ID` | Service principal (app) client ID |
| `AZURE_TENANT_ID` | Home Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

### Environment-level (`dev` and `prod`)

| Secret | Description |
|---|---|
| `CIAM_CLIENT_ID` | App registration client ID from inside the CIAM tenant |
| `CIAM_CLIENT_SECRET` | Corresponding client secret |

## Usage

```bash
cd infra/environments/dev
terraform init
terraform plan
terraform apply
```
