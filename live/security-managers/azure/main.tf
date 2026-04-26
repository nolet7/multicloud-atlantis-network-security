provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "security" {
  name     = "olalat-security-rg"
  location = var.location
}

resource "azurerm_key_vault" "main" {
  name                          = "olalat-security-kv001"
  location                      = azurerm_resource_group.security.location
  resource_group_name           = azurerm_resource_group.security.name
  tenant_id                     = "00000000-0000-0000-0000-000000000000"
  sku_name                      = "standard"
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
}
