resource "azurerm_storage_account" "k8-devops-sa" {
  name                     = var.storage_account_name
  resource_group_name      = local.resource_group_name
  location                 = local.resource_group_location
  account_kind             = var.account_kind
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
}

resource "azurerm_storage_container" "k8-devops-container" {
  name                  = "${var.resource_group_name_prefix}-storage-container"
  storage_account_name  = azurerm_storage_account.k8-devops-sa.name
  #storage_account_id    = azurerm_storage_account.k8-devops-sa.id
  container_access_type = var.container_access_type
}

resource "azurerm_storage_blob" "ansible_file" {
  name                   = "playbook.yaml"
  storage_account_name   = azurerm_storage_account.k8-devops-sa.name
  storage_container_name = azurerm_storage_container.k8-devops-container.name
  type                   = "Block"
  source                 = "${path.module}/ansible/playbook.yaml"
}

resource "azurerm_role_assignment" "blob_data_owner_role_assignment" {
  count                 = local.num_of_masters 
  scope                 = azurerm_storage_container.k8-devops-container.resource_manager_id
  role_definition_name  = "Storage Blob Data Contributor" 
  principal_id          = azurerm_linux_virtual_machine.masternode[count.index].identity[0].principal_id
}
