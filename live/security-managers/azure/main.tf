terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "security" {
  name     = "rg-multicloud-security-${var.environment}"
  location = var.location
}

resource "azurerm_key_vault" "automation" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.security.location
  resource_group_name        = azurerm_resource_group.security.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  enable_rbac_authorization  = true

  tags = {
    Owner       = "platform-engineering"
    Environment = var.environment
    ManagedBy   = "terraform-atlantis"
  }
}
