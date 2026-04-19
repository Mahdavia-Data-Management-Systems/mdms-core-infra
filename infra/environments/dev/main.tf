module "entra" {
  source = "../../modules/entra"

  resource_group_name = "rg-mdms-dev-si-01"
  domain_name         = "mahdavisonlinedev.onmicrosoft.com"
}
