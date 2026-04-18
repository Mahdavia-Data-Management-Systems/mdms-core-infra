module "b2c" {
  source = "../../modules/b2c"

  resource_group_name     = "rg-mdms-prod-si-01"
  location                = "southindia"
  domain_name             = "mdms.onmicrosoft.com"
  display_name            = "MDMS B2C"
  sku_name                = "PremiumP1"
  country_code            = "IN"
  data_residency_location = "Asia Pacific"

  tags = {
    environment = "prod"
    project     = "mdms"
    managed_by  = "terraform"
  }
}
