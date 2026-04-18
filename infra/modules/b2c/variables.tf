variable "resource_group_name" {
  description = "Name of the resource group that hosts the B2C directory resource."
  type        = string
}

variable "location" {
  description = "Azure region for the resource group (B2C itself is global)."
  type        = string
  default     = "southindia"
}

variable "domain_name" {
  description = "Initial domain name for the B2C tenant (e.g. myapp.onmicrosoft.com)."
  type        = string
}

variable "display_name" {
  description = "Human-readable display name for the B2C tenant."
  type        = string
}

variable "sku_name" {
  description = "SKU for the B2C tenant. One of: Standard, PremiumP1, PremiumP2."
  type        = string
  default     = "PremiumP1"

  validation {
    condition     = contains(["Standard", "PremiumP1", "PremiumP2"], var.sku_name)
    error_message = "sku_name must be one of: Standard, PremiumP1, PremiumP2."
  }
}

variable "country_code" {
  description = "Two-letter ISO 3166-1 alpha-2 country code (e.g. US, GB)."
  type        = string
  default     = "IN"
}

variable "data_residency_location" {
  description = "Data residency region. One of: United States, Europe, Asia Pacific, Australia, Japan."
  type        = string
  default     = "Asia Pacific"

  validation {
    condition = contains([
      "United States", "Europe", "Asia Pacific", "Australia", "Japan"
    ], var.data_residency_location)
    error_message = "Invalid data_residency_location."
  }
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
