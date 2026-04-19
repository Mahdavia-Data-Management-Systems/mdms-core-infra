variable "resource_group_name" {
  description = "Name of the resource group that hosts the B2C directory resource."
  type        = string
}

variable "domain_name" {
  description = "Domain name of the existing B2C tenant (e.g. myapp.onmicrosoft.com)."
  type        = string
}
