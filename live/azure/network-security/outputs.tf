output "azure_resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "azure_vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "azure_nsg_name" {
  value = azurerm_network_security_group.app.name
}
