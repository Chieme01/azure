output "azurerm_linux_virtual_machine_name" {
  value = [for v in azurerm_linux_virtual_machine.masternode : v.name] 
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}