resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_static_web_app" "this" {
  name                = var.static_webapp_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku_tier            = var.sku_tier
  sku_size            = var.sku_tier
  tags                = var.tags
  # Identity for accessing other Azure resources
  dynamic "identity" {
    for_each = var.enable_managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }
}

# --- Optional: Application Insights ---

resource "azurerm_log_analytics_workspace" "this" {
  count               = var.enable_application_insights ? 1 : 0
  name                = "${var.static_webapp_name}-laws"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "this" {
  count               = var.enable_application_insights ? 1 : 0
  name                = "${var.static_webapp_name}-ai"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  workspace_id        = azurerm_log_analytics_workspace.this[0].id
  application_type    = "web"
  tags                = var.tags
}

# --- Optional: Custom Domain ---

resource "azurerm_static_web_app_custom_domain" "this" {
  count           = var.custom_domain != null ? 1 : 0
  static_web_app_id = azurerm_static_web_app.this.id
  domain_name     = var.custom_domain
  validation_type = "cname-delegation"
}
