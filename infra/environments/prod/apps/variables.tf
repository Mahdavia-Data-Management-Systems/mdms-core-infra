variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "ciam_client_id" {
  description = "Client ID of the admin app registration inside the prod CIAM tenant. Requires Application.ReadWrite.All."
  type        = string
}

variable "ciam_client_secret" {
  description = "Client secret for the prod CIAM tenant admin app registration."
  type        = string
  sensitive   = true
}
