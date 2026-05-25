output "app_id" {
  description = "The application (client) ID of the registered application."
  value       = data.external.app.result.app_id
}

output "object_id" {
  description = "The object ID of the application registration."
  value       = data.external.app.result.object_id
}

output "display_name" {
  description = "The display name of the application registration."
  value       = var.display_name
}

output "service_principal_object_id" {
  description = "The object ID of the service principal for this application."
  value       = data.external.app.result.service_principal_object_id
}
