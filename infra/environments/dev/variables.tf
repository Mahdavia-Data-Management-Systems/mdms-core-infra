variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  sensitive   = true
}

variable "ciam_client_id" {
  description = "Client ID of the app registration inside the dev CIAM tenant used to apply branding."
  type        = string
}

variable "ciam_client_secret" {
  description = "Client secret for the dev CIAM tenant app registration."
  type        = string
  sensitive   = true
}

variable "google_client_id" {
  description = "Google OAuth2 client ID for the dev environment."
  type        = string
  default     = null
  nullable    = true
}

variable "google_client_secret" {
  description = "Google OAuth2 client secret for the dev environment."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}

variable "facebook_client_id" {
  description = "Facebook app ID for the dev environment."
  type        = string
  default     = null
  nullable    = true
}

variable "facebook_client_secret" {
  description = "Facebook app secret for the dev environment."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}
