output "default_host_name" {
  description = "The default hostname of the Static Web App (e.g. polite-sand-abc123.azurestaticapps.net)."
  value       = azurerm_static_web_app.this.default_host_name
}

output "api_key" {
  description = "Deployment API key used by GitHub Actions to publish the site. Store as a GitHub secret."
  value       = azurerm_static_web_app.this.api_key
  sensitive   = true
}

output "static_webapp_id" {
  description = "Resource ID of the Azure Static Web App."
  value       = azurerm_static_web_app.this.id
}

output "application_insights_connection_string" {
  description = "Application Insights connection string. Null when enable_application_insights is false."
  value       = var.enable_application_insights ? azurerm_application_insights.this[0].connection_string : null
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key. Null when enable_application_insights is false."
  value       = var.enable_application_insights ? azurerm_application_insights.this[0].instrumentation_key : null
  sensitive   = true
}
