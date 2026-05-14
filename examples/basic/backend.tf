# Remote state backend — values are supplied at runtime via -backend-config flags
# or by the reusable GitHub Actions workflow via secrets.
#
# Run locally:
#   tofu init \
#     -backend-config="resource_group_name=<rg>" \
#     -backend-config="storage_account_name=<sa>" \
#     -backend-config="container_name=<container>" \
#     -backend-config="key=myapp/terraform.tfstate"

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {}
}
