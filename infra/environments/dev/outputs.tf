output "tenant_id" {
  description = "B2C tenant ID."
  value       = module.b2c.tenant_id
}

output "b2c_tenant_domain" {
  description = "B2C tenant domain."
  value       = module.b2c.b2c_tenant_domain
}
