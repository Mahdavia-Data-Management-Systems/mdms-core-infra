# Infrastructure as Code

Manages cloud infrastructure using Terraform. State is stored in Terraform Cloud under the `noormahdi` organization.

## Structure

```
infra/
├── modules/
│   └── b2c/                # Azure AD B2C tenant module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/                # TFC workspace: core-dev
    │   ├── versions.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── prod/               # TFC workspace: core-prod
        ├── versions.tf
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Environments

| Environment | Resource Group | B2C Domain | TFC Workspace |
|---|---|---|---|
| dev | rg-mdms-dev-si-01 | mdmsdev.onmicrosoft.com | core-dev |
| prod | rg-mdms-prod-si-01 | mdms.onmicrosoft.com | core-prod |

All resource groups are located in **South India**. B2C data residency is **Asia Pacific**.

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
- Terraform Cloud account in the `noormahdi` organization with workspaces `core-dev` and `core-prod` set to **Local** execution mode
- Azure service principal with `Contributor` and `Application Administrator` roles, configured with a federated credential for this repository

## Required GitHub Secrets

| Secret | Description |
|---|---|
| `TF_API_TOKEN` | Terraform Cloud API token |
| `AZURE_CLIENT_ID` | Service principal (app) client ID |
| `AZURE_TENANT_ID` | Home Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

## Usage

```bash
cd infra/environments/dev
terraform init
terraform plan
terraform apply
```
