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
