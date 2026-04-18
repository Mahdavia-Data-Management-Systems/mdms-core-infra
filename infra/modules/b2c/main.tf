resource "azurerm_resource_group" "b2c" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_aadb2c_directory" "this" {
  resource_group_name     = azurerm_resource_group.b2c.name
  domain_name             = var.domain_name
  display_name            = var.display_name
  sku_name                = var.sku_name
  country_code            = var.country_code
  data_residency_location = var.data_residency_location
  tags                    = var.tags
}
