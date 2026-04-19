module "entra" {
  source = "../../modules/entra"

  resource_group_name = "rg-mdms-prod-si-01"
  domain_name         = "mahdavisonline.onmicrosoft.com"
}
