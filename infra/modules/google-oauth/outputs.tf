output "project_id" {
  description = "GCP project ID."
  value       = google_project.mdms.project_id
}

output "client_id" {
  description = "Google OAuth2 client ID for use as the Google identity provider in Entra External ID."
  value       = local.oauth_creds.client_id
}

output "client_secret" {
  description = "Google OAuth2 client secret."
  value       = local.oauth_creds.client_secret
  sensitive   = true
}
