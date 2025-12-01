# Azure provider configuration
# Replace SUBSCRIPTION_ID and TENANT_ID with your Azure values

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # Option 1: Use service principal authentication (set in environment or tfvars)
  # client_id     = var.client_id
  # client_secret = var.client_secret

  # Option 2: Use Azure CLI authentication (default if client_id not set)
  # Run: az login

  # Option 3: Use managed identity (for CI/CD runners in Azure)
  # use_msi = true
}
