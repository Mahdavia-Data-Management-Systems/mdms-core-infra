module "b2c" {
  source = "../../modules/b2c"

  resource_group_name     = "rg-mdms-dev-si-01"
  location                = "southindia"
  domain_name             = "mdmsdev.onmicrosoft.com"
  display_name            = "MDMS B2C (Dev)"
  sku_name                = "PremiumP1"
  country_code            = "IN"
  data_residency_location = "Asia Pacific"

  tags = {
    environment = "dev"
    project     = "mdms"
    managed_by  = "terraform"
  }
}
