variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group to create."
}

variable "location" {
  type        = string
  description = "Azure region (e.g. \"East US\")."
  default     = "East US"
}

variable "static_webapp_name" {
  type        = string
  description = "Name for the Azure Static Web App resource."
}
