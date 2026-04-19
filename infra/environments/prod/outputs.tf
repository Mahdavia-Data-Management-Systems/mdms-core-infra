output "tenant_id" {
  description = "Entra External ID tenant ID."
  value       = module.entra.tenant_id
}

output "tenant_domain" {
  description = "Entra External ID tenant domain."
  value       = module.entra.tenant_domain
}
