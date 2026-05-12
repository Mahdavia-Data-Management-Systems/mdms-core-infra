# All 7 redirect URIs required by Microsoft Entra External ID for Google federation.
# See: https://learn.microsoft.com/en-us/entra/external-id/customers/how-to-google-federation-customers
locals {
  redirect_uris = [
    "https://login.microsoftonline.com",
    "https://login.microsoftonline.com/te/${var.entra_tenant_id}/oauth2/authresp",
    "https://login.microsoftonline.com/te/${var.entra_tenant_subdomain}.onmicrosoft.com/oauth2/authresp",
    "https://${var.entra_tenant_id}.ciamlogin.com/${var.entra_tenant_id}/federation/oidc/accounts.google.com",
    "https://${var.entra_tenant_id}.ciamlogin.com/${var.entra_tenant_subdomain}.onmicrosoft.com/federation/oidc/accounts.google.com",
    "https://${var.entra_tenant_subdomain}.ciamlogin.com/${var.entra_tenant_id}/federation/oauth2",
    "https://${var.entra_tenant_subdomain}.ciamlogin.com/${var.entra_tenant_subdomain}.onmicrosoft.com/federation/oauth2",
  ]
}

# Look up the existing GCP project to get its numeric project number,
# which is required for the Secret Manager resource path.
data "google_project" "mdms" {
  project_id = var.project_id
}

# ── Enable required APIs ──────────────────────────────────────────────────────
resource "google_project_service" "iap" {
  project            = var.project_id
  service            = "iap.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# ── OAuth consent screen ──────────────────────────────────────────────────────
#
# google_iap_brand provisions the OAuth consent screen for the project.
# org_internal_only = false allows external (non-org) Google accounts to sign in,
# which is required for customer-facing federation.
#
# resource "google_iap_brand" "oauth_brand" {
#   project           = var.project_id
#   support_email     = var.support_email
#   application_title = var.oauth_client_display_name
#   depends_on        = [google_project_service.iap]
# }

# ── Secret Manager secret (container) ────────────────────────────────────────
#
# Stores the OAuth2 client credentials created by the local-exec script below.
# The secret value (version) is written by the script on first apply.
#
resource "google_secret_manager_secret" "oauth_creds" {
  project   = var.project_id
  secret_id = "google-oauth-client-creds"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

# ── OAuth2 web application client (via gcloud CLI) ────────────────────────────
#
# The google_iap_client resource creates IAP-type clients which do not support
# custom redirect URIs. For Entra federation we need a CONFIDENTIAL_CLIENT type
# with specific redirect URIs, which requires the gcloud alpha oauth-clients API.
#
# The script:
#   1. Checks whether credentials are already stored in Secret Manager (idempotent).
#   2. If not, creates the OAuth client with all required redirect URIs.
#   3. Stores {client_id, client_secret} as JSON in Secret Manager.
#
resource "terraform_data" "oauth_client" {
  triggers_replace = [
    # google_iap_brand.oauth_brand.name,
    join(",", local.redirect_uris),
    var.oauth_client_display_name,
  ]

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/create-oauth-client.sh"

    environment = {
      PROJECT_ID    = var.project_id
      DISPLAY_NAME  = var.oauth_client_display_name
      REDIRECT_URIS = join(",", local.redirect_uris)
      SECRET_NAME   = "projects/${data.google_project.mdms.number}/secrets/${google_secret_manager_secret.oauth_creds.secret_id}"
    }
  }
}

# ── Read credentials back from Secret Manager ─────────────────────────────────
data "google_secret_manager_secret_version" "oauth_creds" {
  project    = var.project_id
  secret     = google_secret_manager_secret.oauth_creds.secret_id
  depends_on = [terraform_data.oauth_client]
}

locals {
  oauth_creds = jsondecode(data.google_secret_manager_secret_version.oauth_creds.secret_data)
}
