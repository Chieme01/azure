# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  #resource_provider_registrations = "none"
  features {
    resource_group {
      prevent_deletion_if_contains_resources  = false
    }
    virtual_machine {
      delete_os_disk_on_deletion              = true
    }
    key_vault {
      purge_soft_delete_on_destroy            = true
      purge_soft_deleted_keys_on_destroy      = true
      purge_soft_deleted_secrets_on_destroy   = true
    }
  }

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
    
}