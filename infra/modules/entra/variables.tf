variable "resource_group_name" {
  description = "Name of the resource group that hosts the B2C directory resource."
  type        = string
}

variable "domain_name" {
  description = "Domain name of the existing B2C tenant (e.g. myapp.onmicrosoft.com)."
  type        = string
}

variable "ciam_client_id" {
  description = "Client ID of the app registration inside the CIAM tenant used to apply branding (requires Organization.ReadWrite.All)."
  type        = string
}

variable "ciam_client_secret" {
  description = "Client secret for the CIAM tenant app registration."
  type        = string
  sensitive   = true
}

variable "branding_sign_in_text" {
  description = "Text displayed below the sign-in box on the CIAM tenant sign-in page."
  type        = string
  default     = "One Identity. One Community. Endless Access."
}

variable "google_client_id" {
  description = "Google OAuth2 client ID used to configure Google as a social identity provider in the CIAM tenant."
  type        = string
  default     = null
  nullable    = true
}

variable "google_client_secret" {
  description = "Google OAuth2 client secret for the social identity provider."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}

variable "facebook_client_id" {
  description = "Facebook app ID used to configure Facebook as a social identity provider in the CIAM tenant."
  type        = string
  default     = null
  nullable    = true
}

variable "facebook_client_secret" {
  description = "Facebook app secret for the social identity provider."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}
