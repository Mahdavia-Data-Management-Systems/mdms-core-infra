# Infrastructure as Code

Manages cloud infrastructure using Terraform. State is stored in Terraform Cloud under the `noormahdi` organization.

## Structure

```
infra/
├── modules/
│   ├── entra/                      # Entra External ID (CIAM) tenant module
│   │   ├── main.tf                 # Data source: reads existing CIAM directory
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── branding.tf             # Custom branding via Microsoft Graph API
│   │   ├── google-idp.tf           # Google social identity provider
│   │   ├── facebook-idp.tf         # Facebook social identity provider
│   │   ├── assets/                 # banner-logo.png, square-logo.jpg, favicon.ico
│   │   ├── css/
│   │   │   └── custom.css          # Sign-in page styles
│   │   └── scripts/
│   │       ├── apply-branding.ps1
│   │       ├── apply-google-idp.ps1
│   │       ├── apply-facebook-idp.ps1
│   │       └── idp-helpers.ps1     # Shared: Get-GraphToken, Set-SocialIdentityProvider
│   ├── entra-app/                  # App registration provisioning module
│   │   ├── main.tf                 # terraform_data with create + destroy provisioners
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── scripts/
│   │       ├── apply-app.ps1       # Create/update app registration + service principal
│   │       ├── delete-app.ps1      # Delete app registration + service principal
│   │       ├── get-app.ps1         # Query app details (external data source)
│   │       └── app-helpers.ps1     # Shared: Get-GraphToken, Set-AppRegistration, etc.
└── environments/
    ├── dev/
    │   ├── core/                   # CIAM tenant config — TFC workspace: core-dev
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── outputs.tf
    │   │   └── versions.tf
    │   └── apps/                   # App registrations — TFC workspace: apps-dev
    │       ├── main.tf
    │       ├── apps.yaml           # Declarative app definitions
    │       ├── variables.tf
    │       ├── outputs.tf
    │       └── versions.tf
    └── prod/
        ├── core/                   # CIAM tenant config — TFC workspace: core-prod
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── versions.tf
        └── apps/                   # App registrations — TFC workspace: apps-prod
            ├── main.tf
            ├── apps.yaml
            ├── variables.tf
            ├── outputs.tf
            └── versions.tf
```

## Environments

| Environment | Resource Group | Entra Domain | TFC Workspace (core) | TFC Workspace (apps) |
|---|---|---|---|---|
| dev | rg-mdms-dev-si-01 | mahdavisonlinedev.onmicrosoft.com | core-dev | apps-dev |
| prod | rg-mdms-prod-si-01 | mahdavisonline.onmicrosoft.com | core-prod | apps-prod |

All resource groups are located in **South India**.

## Providers

| Provider | Source | Purpose |
|---|---|---|
| `azurerm` | `hashicorp/azurerm ~> 3.110` | Core Azure resource management |
| `azapi` | `azure/azapi ~> 1.15` | Entra External ID (CIAM) directory lookup |
| `external` | `hashicorp/external ~> 2.3` | Query app details after creation (entra-app module) |

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

## Social Identity Providers

`google-idp.tf` and `facebook-idp.tf` register Google and Facebook as social identity providers via Microsoft Graph API.

- Each IDP resource uses `count = var.<provider>_client_id != null ? 1 : 0` — the IDP is skipped if credentials are not provided.
- Scripts: `scripts/apply-google-idp.ps1`, `scripts/apply-facebook-idp.ps1` (shared helpers in `idp-helpers.ps1`).
- Required Graph API permission: `IdentityProvider.ReadWrite.All`.

## App Registrations

App registrations are declared in `apps.yaml` per environment and provisioned via the `entra-app` module using Microsoft Graph API with full lifecycle management (create on `apply`, delete on `destroy`).

**`apps.yaml` format:**

```yaml
apps:
  - name: sample-app              # Terraform resource key (no spaces)
    display_name: "Sample App"    # Azure portal display name
    app_type: web                 # "spa" (public, PKCE) or "web" (confidential)
    redirect_uris:
      - https://example.com/callback
    logout_url: https://example.com/signout   # web only; omit for SPA
    sign_in_audience: AzureADandPersonalMicrosoftAccount  # optional
```

- `app_type: spa` — uses `spa.redirectUris`; implicit grant enabled.
- `app_type: web` — uses `web.redirectUris` and `web.logoutUrl`; implicit grant enabled.
- A service principal is created automatically alongside each app registration.
- `get-app.ps1` retries up to 10 times (6 s delay) to handle Graph API eventual consistency after creation.

### One-time CIAM tenant setup (per environment)

1. Create an app registration **inside** the CIAM tenant (not the home tenant).
2. Grant the following application permissions and admin-consent them:
   - `Organization.ReadWrite.All` — for branding
   - `Application.ReadWrite.All` — for app registrations
   - `IdentityProvider.ReadWrite.All` — for social IDPs
3. Create a client secret.
4. Add `CIAM_CLIENT_ID` as an **environment variable** and `CIAM_CLIENT_SECRET` as an **environment secret** on the corresponding GitHub Environment (`dev` / `prod`).

## CI/CD Pipelines

### Core pipeline (`main.yml`)

Manages CIAM tenant configuration (branding, social IDPs). Triggered on push to `main` (excluding `infra/environments/*/apps/**`) and manual dispatch.

| Stage | Trigger | Manual approval |
|---|---|---|
| Validate | Always | No |
| Deploy (dev) | Always, after validate | No |
| Deploy (prod) | Manual dispatch, after dev succeeds | Yes — configured on the `prod` GitHub Environment |

### Apps pipelines

| Pipeline | Trigger path | Stage |
|---|---|---|
| `apps-dev.yml` | `infra/environments/dev/apps/**` | validate → deploy-dev-apps |
| `apps-prod.yml` | `infra/environments/prod/apps/**` | validate → deploy-prod-apps |

Prod apps pipeline requires approval via the `prod` GitHub Environment.

### Azure authentication

GitHub authenticates to Azure via **federated credentials (OIDC)** — no client secret required.

## Prerequisites

- Terraform >= 1.7
- PowerShell 7+ (`pwsh`) — for branding, IDP, and app provisioner scripts
- Terraform Cloud account in the `noormahdi` organization with workspaces `core-dev`, `core-prod`, `apps-dev`, `apps-prod` set to **Local** execution mode
- Azure service principal with `Contributor` role, configured with federated credentials for the `dev` and `prod` GitHub Environments

## Usage

```bash
# Core CIAM tenant configuration
cd infra/environments/dev/core
terraform init
terraform plan
terraform apply

# App registrations
cd infra/environments/dev/apps
terraform init
terraform plan
terraform apply
```
