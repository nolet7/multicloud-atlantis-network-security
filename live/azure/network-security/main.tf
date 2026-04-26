resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-${var.environment}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_cidr]

  tags = {
    Owner       = "platform-team"
    CostCenter  = "shared-services"
    Environment = var.environment
  }
}

resource "azurerm_network_security_group" "web" {
  name                = "${var.project_name}-${var.environment}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Owner       = "platform-team"
    CostCenter  = "shared-services"
    Environment = var.environment
  }
}
