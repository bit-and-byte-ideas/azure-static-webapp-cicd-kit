provider "azurerm" {
  features {}
}

module "static_webapp" {
  source = "../../modules/azure-static-webapp"

  resource_group_name = var.resource_group_name
  static_webapp_name  = var.static_webapp_name

  # Optional features — uncomment to enable
  # sku_tier                    = "Standard"
  # enable_managed_identity     = true   # requires sku_tier = "Standard"
  # enable_application_insights = true
  # custom_domain               = "www.example.com"

  tags = {
    environment = "production"
    managed_by  = "opentofu"
  }
}

output "site_url" {
  value = "https://${module.static_webapp.default_host_name}"
}

output "deployment_api_key" {
  description = "Store this value as the AZURE_STATIC_WEB_APPS_API_TOKEN secret in your site's repository."
  value       = module.static_webapp.api_key
  sensitive   = true
}
