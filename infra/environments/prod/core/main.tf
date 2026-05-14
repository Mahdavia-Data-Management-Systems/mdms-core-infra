module "entra" {
  source = "../../../modules/entra"

  resource_group_name = "rg-mdms-prod-si-01"
  domain_name         = "mahdavisonline.onmicrosoft.com"

  ciam_client_id     = var.ciam_client_id
  ciam_client_secret = var.ciam_client_secret

  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret

  facebook_client_id     = var.facebook_client_id
  facebook_client_secret = var.facebook_client_secret
}
