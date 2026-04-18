output "tenant_id" {
  description = "The tenant ID of the B2C directory."
  value       = azurerm_aadb2c_directory.this.tenant_id
}

output "b2c_tenant_domain" {
  description = "The primary domain of the B2C tenant."
  value       = azurerm_aadb2c_directory.this.domain_name
}

output "resource_group_id" {
  description = "Resource group ID."
  value       = azurerm_resource_group.b2c.id
}
