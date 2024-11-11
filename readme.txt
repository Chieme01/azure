Required parameters:
subscription_id     
tenant_id      

HOW TO USE:
module "kubernetes_cluster" {
  source                = "github.com/Chieme01/azure"
}

provider "azurerm" {
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

Cool things:
Azure System Assigned identity
Terraform conditional statements
Use of Terraform for loops
Azure VM Custom Data and Cloud-init
Azure VM Extensions
