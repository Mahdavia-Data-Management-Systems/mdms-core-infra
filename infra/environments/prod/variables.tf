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

variable "google_client_id" {
  description = "Google OAuth2 client ID for the prod environment."
  type        = string
}

variable "google_client_secret" {
  description = "Google OAuth2 client secret for the prod environment."
  type        = string
  sensitive   = true
}
