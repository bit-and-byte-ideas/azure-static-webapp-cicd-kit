mock_provider "azurerm" {
  # azurerm_application_insights.workspace_id is validated against the full
  # Azure resource ID format at plan time. Override the mock id so the
  # cross-resource reference resolves to a valid-looking ID.
  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-app-laws"
    }
  }
}

# Shared variables used across most tests.
variables {
  resource_group_name = "test-rg"
  static_webapp_name  = "test-app"
}

# ---------------------------------------------------------------------------
# Baseline: free tier + all optional features disabled (the defaults)
# ---------------------------------------------------------------------------
run "default_free_tier_creates_only_static_webapp" {
  command = plan

  assert {
    condition     = azurerm_static_web_app.this.sku_tier == "Free"
    error_message = "Default sku_tier must be Free."
  }

  assert {
    condition     = length(azurerm_log_analytics_workspace.this) == 0
    error_message = "Log Analytics workspace must not be created when enable_application_insights is false."
  }

  assert {
    condition     = length(azurerm_application_insights.this) == 0
    error_message = "Application Insights must not be created when enable_application_insights is false."
  }

  assert {
    condition     = length(azurerm_static_web_app_custom_domain.this) == 0
    error_message = "Custom domain resource must not be created when custom_domain is null."
  }
}

# ---------------------------------------------------------------------------
# Validation: managed identity on Free tier must be rejected at plan time
# ---------------------------------------------------------------------------
run "managed_identity_on_free_tier_is_rejected" {
  command = plan

  variables {
    sku_tier                = "Free"
    enable_managed_identity = true
  }

  expect_failures = [var.enable_managed_identity]
}

# ---------------------------------------------------------------------------
# Standard tier with managed identity succeeds
# ---------------------------------------------------------------------------
run "standard_tier_with_managed_identity" {
  command = plan

  variables {
    sku_tier                = "Standard"
    enable_managed_identity = true
  }

  assert {
    condition     = azurerm_static_web_app.this.sku_tier == "Standard"
    error_message = "sku_tier must be Standard."
  }
}

# ---------------------------------------------------------------------------
# Validation: unsupported SKU tier is rejected at plan time
# ---------------------------------------------------------------------------
run "invalid_sku_tier_is_rejected" {
  command = plan

  variables {
    sku_tier = "Premium"
  }

  expect_failures = [var.sku_tier]
}

# ---------------------------------------------------------------------------
# Application Insights: both dependent resources are created together
# ---------------------------------------------------------------------------
run "application_insights_creates_workspace_and_ai" {
  command = plan

  variables {
    enable_application_insights = true
  }

  assert {
    condition     = length(azurerm_log_analytics_workspace.this) == 1
    error_message = "Log Analytics workspace must be created when enable_application_insights is true."
  }

  assert {
    condition     = length(azurerm_application_insights.this) == 1
    error_message = "Application Insights must be created when enable_application_insights is true."
  }

  assert {
    condition     = azurerm_log_analytics_workspace.this[0].name == "test-app-laws"
    error_message = "Log Analytics workspace name must follow the '<app_name>-laws' naming convention."
  }

  assert {
    condition     = azurerm_application_insights.this[0].name == "test-app-ai"
    error_message = "Application Insights name must follow the '<app_name>-ai' naming convention."
  }
}

# ---------------------------------------------------------------------------
# Custom domain: binding resource is created with the correct values
# ---------------------------------------------------------------------------
run "custom_domain_creates_binding_resource" {
  command = plan

  variables {
    custom_domain = "www.example.com"
  }

  assert {
    condition     = length(azurerm_static_web_app_custom_domain.this) == 1
    error_message = "Custom domain resource must be created when custom_domain is set."
  }

  assert {
    condition     = azurerm_static_web_app_custom_domain.this[0].domain_name == "www.example.com"
    error_message = "domain_name must match the custom_domain input variable."
  }

  assert {
    condition     = azurerm_static_web_app_custom_domain.this[0].validation_type == "cname-delegation"
    error_message = "validation_type must always be cname-delegation."
  }
}

# ---------------------------------------------------------------------------
# Tags: passed through to the Static Web App
# ---------------------------------------------------------------------------
run "tags_are_propagated_to_static_webapp" {
  command = plan

  variables {
    tags = {
      environment = "test"
      team        = "infrastructure"
    }
  }

  assert {
    condition     = azurerm_static_web_app.this.tags["environment"] == "test"
    error_message = "The environment tag must be propagated to the Static Web App."
  }

  assert {
    condition     = azurerm_static_web_app.this.tags["team"] == "infrastructure"
    error_message = "The team tag must be propagated to the Static Web App."
  }
}
