module "entra" {
  source = "../../modules/entra"

  resource_group_name = "rg-mdms-dev-si-01"
  domain_name         = "mahdavisonlinedev.onmicrosoft.com"

  ciam_client_id     = var.ciam_client_id
  ciam_client_secret = var.ciam_client_secret
}
