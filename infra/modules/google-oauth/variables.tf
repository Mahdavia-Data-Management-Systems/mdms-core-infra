variable "project_id" {
  description = "ID of the existing GCP project to configure the OAuth app in."
  type        = string
}

variable "support_email" {
  description = "Email address shown on the Google OAuth consent screen."
  type        = string
}

variable "oauth_client_display_name" {
  description = "Display name for the OAuth2 client shown to users on the Google sign-in screen."
  type        = string
  default     = "Microsoft Entra External ID"
}

variable "entra_tenant_id" {
  description = "Entra External ID (CIAM) tenant ID — used to build the authorized redirect URIs required for federation."
  type        = string
}

variable "entra_tenant_subdomain" {
  description = "Entra External ID tenant subdomain (e.g. \"mahdavisonlinedev\" for mahdavisonlinedev.onmicrosoft.com)."
  type        = string
}
