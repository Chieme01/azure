output "azurerm_linux_virtual_machine_name" {
  value = [for v in azurerm_linux_virtual_machine.masternode : v.name] 
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  value = azurerm_resource_group.rg.location
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "key_vault_name" {
  value = azurerm_key_vault.key_vault.name
}

output "key_vault_id" {
  value = azurerm_key_vault.key_vault.id
}