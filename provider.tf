

# Configure the Microsoft Azure Provider
provider "azurerm" {
  #resource_provider_registrations = "none"
  features {
    resource_group {
      prevent_deletion_if_contains_resources  = false
    }
    virtual_machine {
      delete_os_disk_on_deletion              = true
      #skip_shutdown_and_force_delete          = 
      #detach_implicit_data_disk_on_deletion   = 
    }
    key_vault {
      purge_soft_delete_on_destroy            = true
      purge_soft_deleted_keys_on_destroy      = true
      purge_soft_deleted_secrets_on_destroy   = true
    }
  }

  subscription_id                             = var.subscription_id
  tenant_id                                   = var.tenant_id
    
}