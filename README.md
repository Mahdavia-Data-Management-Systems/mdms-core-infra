# Mahdavia Data Management System (MDMS)

Cloud infrastructure and data management platform for Mahdavia, built on Azure with infrastructure managed via Terraform.

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── main.yml        # CI/CD pipeline
├── infra/
│   ├── modules/
│   │   └── entra/          # Entra External ID (CIAM) tenant module
│   └── environments/
│       ├── dev/            # Dev environment
│       └── prod/           # Prod environment
└── docs/                   # Project documentation
```

## Prerequisites

### Tools

| Tool | Version | Install |
|---|---|---|
| Terraform | >= 1.7 | https://developer.hashicorp.com/terraform/install |
| Azure CLI | Latest | https://learn.microsoft.com/en-us/cli/azure/install-azure-cli |

### Terraform Cloud

1. Create an account at https://app.terraform.io
2. Create an organization named `noormahdi`
3. Create two workspaces: `core-dev` and `core-prod`
4. Set **Execution Mode** to **Local** on both workspaces
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

Add the following secrets at **GitHub repo → Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `TF_API_TOKEN` | Terraform Cloud API token |
| `AZURE_CLIENT_ID` | Service principal app (client) ID |
| `AZURE_TENANT_ID` | Home Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

### GitHub — Environments

Create two environments at **GitHub repo → Settings → Environments**:

| Environment | Protection rule |
|---|---|
| `dev` | None — deploys automatically |
| `prod` | **Required reviewers** — add yourself to gate prod deployments |

## CI/CD Pipeline

Triggers:
- **Push to `main`** — validates and deploys to dev automatically
- **Manual dispatch** — includes a **Deploy to production** toggle (off by default)

| Stage | Runs when | Approval required |
|---|---|---|
| Validate | Every trigger | No |
| Deploy (dev) | After validate passes | No |
| Deploy (prod) | Manual dispatch with `Deploy to production = true`, after dev succeeds | Yes |

## Infrastructure

See [`infra/README.md`](infra/README.md) for full details on the Terraform module structure, environments, and resource configurations.
