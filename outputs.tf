output "master_nodes_name" {
  value = [for v in azurerm_linux_virtual_machine.masternode : v.name] 
}

output "master_nodes_id" {
  value = [for v in azurerm_linux_virtual_machine.masternode : v.id] 
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

output "storage_account_id" {
  value = azurerm_storage_account.k8-devops-sa.id
}

output "container_id" {
  value = azurerm_storage_container.k8-devops-container.id
}
