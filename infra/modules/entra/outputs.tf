output "tenant_id" {
  description = "The tenant ID of the Entra External ID directory."
  value       = jsondecode(data.azapi_resource.entra.output).properties.tenantId
}

output "tenant_domain" {
  description = "The primary domain of the Entra External ID tenant."
  value       = var.domain_name
}

output "resource_group_id" {
  description = "Resource group ID."
  value       = data.azurerm_resource_group.entra.id
}
