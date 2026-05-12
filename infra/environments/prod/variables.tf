variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  sensitive   = true
}

variable "ciam_client_id" {
  description = "Client ID of the app registration inside the prod CIAM tenant used to apply branding."
  type        = string
}

variable "ciam_client_secret" {
  description = "Client secret for the prod CIAM tenant app registration."
  type        = string
  sensitive   = true
}

variable "gcp_project_id" {
  description = "ID of the existing GCP project for the prod Google OAuth app."
  type        = string
}

variable "gcp_support_email" {
  description = "Support email shown on the Google OAuth consent screen."
  type        = string
}

variable "ciam_tenant_id" {
  description = "Entra External ID (CIAM) tenant ID GUID for the prod tenant. Find it in Azure Portal → Entra ID → Overview. Used to build Google OAuth redirect URIs."
  type        = string
}
