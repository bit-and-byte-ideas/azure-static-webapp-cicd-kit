# Azure Static WebApp CI/CD Kit

A reusable OpenTofu module and GitHub Actions workflow for deploying Azure Static Web Apps in a consistent, repeatable pattern.

```
Consumer Repo
│
├── .github/workflows/deploy-infra.yml   ← calls this kit's reusable workflow
└── infra/
    ├── main.tf                          ← calls this kit's OpenTofu module
    └── backend.tf
```

## What's Included

| Path | Purpose |
|---|---|
| `modules/azure-static-webapp/` | OpenTofu module — provisions resource group, Static Web App, and optional resources |
| `.github/workflows/opentofu.yml` | Reusable GitHub Actions workflow — validate → plan → (approval) → apply |
| `examples/basic/` | Minimal working example showing module usage |

## Prerequisites

Before using this kit, ensure you have:

1. **OpenTofu** ≥ 1.6 installed locally for development
2. **Azure CLI** authenticated (`az login`)
3. **Azure App Registration with OIDC** configured (see below)
4. **Azure Storage Account** for remote OpenTofu state
5. **GitHub Environment** named `production` (or your chosen name) with required reviewers configured in your repo's _Settings > Environments_

### Azure OIDC Setup

Create an App Registration and federated credential so GitHub Actions can authenticate without a stored secret:

```bash
# 1. Create App Registration
APP_ID=$(az ad app create --display-name "github-opentofu" --query appId -o tsv)
az ad sp create --id $APP_ID

# 2. Add federated credential (replace ORG/REPO with your values)
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-actions",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:ORG/REPO:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# 3. Assign Contributor role on your subscription
az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

### State Storage Account

```bash
az storage account create \
  --name <storage_account_name> \
  --resource-group <rg_name> \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name <storage_account_name>
```

---

## Module Usage

```hcl
# infra/main.tf
provider "azurerm" {
  features {}
}

module "static_webapp" {
  source = "github.com/bit-and-byte-ideas/azure-static-webapp-cicd-kit//modules/azure-static-webapp"

  resource_group_name = "my-app-rg"
  location            = "East US"
  static_webapp_name  = "my-app"

  # Optional features
  sku_tier                    = "Standard"   # default: "Free"
  enable_application_insights = true         # default: false
  custom_domain               = "www.example.com"  # default: null

  tags = {
    environment = "production"
  }
}
```

```hcl
# infra/backend.tf
terraform {
  backend "azurerm" {}
}
```

Init with backend config:

```bash
tofu init \
  -backend-config="resource_group_name=<rg>" \
  -backend-config="storage_account_name=<sa>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=my-app/terraform.tfstate"
```

---

## Workflow Usage

In your consumer repo, create a workflow that calls this kit:

```yaml
# .github/workflows/deploy-infra.yml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  opentofu:
    uses: bit-and-byte-ideas/azure-static-webapp-cicd-kit/.github/workflows/opentofu.yml@main
    with:
      working_directory: infra
      environment: production      # must match your GitHub Environment name
    secrets:
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      TF_BACKEND_RESOURCE_GROUP: ${{ secrets.TF_BACKEND_RESOURCE_GROUP }}
      TF_BACKEND_STORAGE_ACCOUNT: ${{ secrets.TF_BACKEND_STORAGE_ACCOUNT }}
      TF_BACKEND_CONTAINER: ${{ secrets.TF_BACKEND_CONTAINER }}
      TF_BACKEND_KEY: ${{ secrets.TF_BACKEND_KEY }}
```

### Pipeline Behavior

```
push/PR
  │
  ▼
validate ──── fmt check + init (no backend) + validate
  │
  ▼
plan ────────── init (remote state) + tofu plan -detailed-exitcode
  │
  ├── no changes ──► success (apply job skipped)
  │
  └── changes detected
        │
        ▼
      apply ───── requires GitHub Environment approval ──► tofu apply tfplan
```

---

## Required GitHub Secrets

Configure these in your consumer repo's _Settings > Secrets and variables > Actions_:

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | App Registration client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `TF_BACKEND_RESOURCE_GROUP` | Resource group of the state storage account |
| `TF_BACKEND_STORAGE_ACCOUNT` | Storage account name for state |
| `TF_BACKEND_CONTAINER` | Blob container name for state |
| `TF_BACKEND_KEY` | State file path (e.g. `myapp/terraform.tfstate`) |

---

## Module: Optional Features

### Managed Identity

Set `enable_managed_identity = true` to assign a `SystemAssigned` managed identity to the Static Web App, allowing it to authenticate to other Azure services (Key Vault, Storage, etc.) without credentials.

> **Requires `sku_tier = "Standard"`** — Azure does not support managed identities on the Free tier. The module enforces this with a validation rule and will error at plan time if both are misconfigured.

### Application Insights

Set `enable_application_insights = true` to provision an Application Insights instance and a Log Analytics workspace. The module outputs `application_insights_connection_string` and `application_insights_instrumentation_key` (both sensitive).

### Custom Domain

Set `custom_domain = "www.example.com"` to create a `azurerm_static_web_app_custom_domain` resource using CNAME delegation. You must create the DNS CNAME record pointing to `default_host_name` before running apply, or the resource will fail validation.
