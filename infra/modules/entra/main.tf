data "azurerm_resource_group" "entra" {
  name = var.resource_group_name
}

data "azapi_resource" "entra" {
  type      = "Microsoft.AzureActiveDirectory/ciamDirectories@2023-05-17-preview"
  name      = var.domain_name
  parent_id = data.azurerm_resource_group.entra.id

  response_export_values = ["properties.tenantId"]
}
