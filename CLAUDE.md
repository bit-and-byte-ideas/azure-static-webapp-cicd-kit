# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

Reusable OpenTofu module and GitHub Actions reusable workflow (`workflow_call`) that consumer repos reference to provision Azure Static Web Apps consistently.

## Architecture Decisions

| Decision | Choice | Reason |
|---|---|---|
| Azure authentication | OIDC Federated Identity | No stored secrets; uses `azure/login` with `client-id`/`tenant-id`/`subscription-id` |
| Workflow type | `workflow_call` (reusable) | Versioned centrally; consumers call with `uses: org/repo/.github/workflows/opentofu.yml@main` |
| Remote state backend | Azure Blob Storage (`azurerm`) | Backend config passed at `tofu init` time via `-backend-config` flags (no credentials in code) |
| Change detection | `tofu plan -detailed-exitcode` | Exit code 2 = changes present; exit code 0 = no changes; skips apply job when no changes |

## Repository Structure

```
modules/azure-static-webapp/   OpenTofu module (versions, variables, main, outputs)
.github/workflows/opentofu.yml Reusable workflow with 3 jobs: validate → plan → apply
examples/basic/                Minimal consumer example (main.tf, backend.tf, variables.tf)
```

## Module: `modules/azure-static-webapp`

Always-created resources: `azurerm_resource_group`, `azurerm_static_web_app`

Conditional resources:
- `enable_managed_identity = true` → `identity { type = "SystemAssigned" }` block on the Static Web App — **requires `sku_tier = "Standard"`**; enforced by a `validation` block that errors at plan time if Free tier is used with this flag
- `enable_application_insights = true` → `azurerm_log_analytics_workspace` + `azurerm_application_insights`
- `custom_domain != null` → `azurerm_static_web_app_custom_domain` (uses CNAME delegation; DNS must exist first)

Sensitive outputs: `api_key`, `application_insights_connection_string`, `application_insights_instrumentation_key`

## Workflow Jobs

**validate** — `tofu fmt -check -recursive` + `tofu init -backend=false` + `tofu validate` (no Azure credentials)

**plan** — Azure login (OIDC) → `tofu init` (with backend config from secrets) → `tofu plan -detailed-exitcode -out=tfplan` → uploads `tfplan` artifact (1-day retention) → sets `has_changes` output

**apply** — runs only when `has_changes == 'true'`; gated by GitHub Environment (`inputs.environment`, default `production`); downloads plan artifact → `tofu apply -auto-approve tfplan`

## Local Development

```bash
# Init with backend config
tofu init \
  -backend-config="resource_group_name=<rg>" \
  -backend-config="storage_account_name=<sa>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=myapp/terraform.tfstate"

# Plan with variable values
tofu plan \
  -var="resource_group_name=my-rg" \
  -var="location=East US" \
  -var="static_webapp_name=my-app"

# Check formatting
tofu fmt -check -recursive

# Validate without backend
tofu validate
```

## Required GitHub Secrets (consumer repos)

`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` — OIDC auth
`TF_BACKEND_RESOURCE_GROUP`, `TF_BACKEND_STORAGE_ACCOUNT`, `TF_BACKEND_CONTAINER`, `TF_BACKEND_KEY` — remote state
