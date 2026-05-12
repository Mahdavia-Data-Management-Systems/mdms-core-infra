module "google_oauth" {
  source = "../../modules/google-oauth"

  project_id                = var.gcp_project_id
  support_email             = var.gcp_support_email
  oauth_client_display_name = "Microsoft Entra External ID (Dev)"
  entra_tenant_id           = var.ciam_tenant_id
  entra_tenant_subdomain    = "mahdavisonlinedev"
}

module "entra" {
  source = "../../modules/entra"

  resource_group_name = "rg-mdms-dev-si-01"
  domain_name         = "mahdavisonlinedev.onmicrosoft.com"

  ciam_client_id     = var.ciam_client_id
  ciam_client_secret = var.ciam_client_secret

  google_client_id     = module.google_oauth.client_id
  google_client_secret = module.google_oauth.client_secret
}
