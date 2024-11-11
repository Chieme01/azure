data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "key_vault" {
  name                            = "lockkeyvault"
  location                        = local.resource_group_location
  resource_group_name             = local.resource_group_name
  enabled_for_disk_encryption     = true
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days      = 7
  purge_protection_enabled        = false

  sku_name = "standard"
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "ssh-private-key"
  value        = azapi_resource_action.ssh_public_key_gen.output.privateKey
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "secret_private_key" {
  name         = "ssh-public-key"
  value        = azapi_resource_action.ssh_public_key_gen.output.publicKey
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "username" {
  name         = "username"
  value        = var.username
  key_vault_id = azurerm_key_vault.key_vault.id
}