variable "resource_group_name" {
  description = "Name of the resource group that hosts the CIAM directory resource."
  type        = string
}

variable "domain_name" {
  description = "Domain name of the CIAM tenant (e.g. myapp.onmicrosoft.com)."
  type        = string
}

variable "ciam_client_id" {
  description = "Client ID of the admin app registration inside the CIAM tenant. Requires Application.ReadWrite.All."
  type        = string
}

variable "ciam_client_secret" {
  description = "Client secret for the CIAM tenant admin app registration."
  type        = string
  sensitive   = true
}

variable "display_name" {
  description = "Display name for the application registration."
  type        = string
}

variable "app_type" {
  description = "Application platform type: 'spa' (single-page app, PKCE) or 'web' (server-side, confidential)."
  type        = string
  default     = "spa"

  validation {
    condition     = contains(["spa", "web"], var.app_type)
    error_message = "app_type must be 'spa' or 'web'."
  }
}

variable "redirect_uris" {
  description = "List of redirect URIs for the application."
  type        = list(string)
  default     = []
}

variable "logout_url" {
  description = "Front-channel logout URL. Only used when app_type is 'web'."
  type        = string
  default     = null
  nullable    = true
}

variable "sign_in_audience" {
  description = "Sign-in audience for the app registration. Defaults to AzureADandPersonalMicrosoftAccount to allow social IDPs."
  type        = string
  default     = "AzureADandPersonalMicrosoftAccount"
}
