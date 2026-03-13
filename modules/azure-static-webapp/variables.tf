variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group to create."
}

variable "location" {
  type        = string
  description = "Azure region where resources will be deployed (e.g. \"East US\")."
}

variable "static_webapp_name" {
  type        = string
  description = "Name of the Azure Static Web App."
}

variable "sku_tier" {
  type        = string
  description = "SKU tier for the Static Web App. Use \"Free\" for hobby projects or \"Standard\" for production."
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "sku_tier must be \"Free\" or \"Standard\"."
  }
}

variable "enable_managed_identity" {
  type        = bool
  description = "When true, assigns a SystemAssigned managed identity to the Static Web App. Requires sku_tier = \"Standard\"; Azure does not support managed identities on the Free tier."
  default     = false

  validation {
    condition     = !var.enable_managed_identity || var.sku_tier == "Standard"
    error_message = "enable_managed_identity requires sku_tier = \"Standard\". Managed identities are not supported on the Free tier."
  }
}

variable "enable_application_insights" {
  type        = bool
  description = "When true, provisions an Application Insights instance and Log Analytics workspace."
  default     = false
}

variable "custom_domain" {
  type        = string
  description = "Custom domain to bind to the Static Web App (e.g. \"www.example.com\"). Set to null to skip."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Azure resource tags to apply to all provisioned resources."
  default     = {}
}
