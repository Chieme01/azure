*****************************************************************************************************************************
ABOUT
*****************************************************************************************************************************
This module is to deploy Kubernetes cluster on Azure Virtual Machines, intended for practising Kubernetes in a cloud lab environment. 
It is not a solution for production environments. 
It also provisions other basic, and dependent resources like Virtual Network, NAT Gateway, Bastion Host, Key Vault Secret Engine and others.

*****************************************************************************************************************************
HOW TO USE
*****************************************************************************************************************************
module "kubernetes_cluster" {
  source                                      = "github.com/Chieme01/azure"
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

  subscription_id = <YOUR SUBSCRIPTION ID>
  tenant_id       = <YOUR TENANT ID>
}

*****************************************************************************************************************************
COOL THINGS TO TAKE NOTE OF
*****************************************************************************************************************************
- Azure System Assigned identity
- Terraform conditional statements
- Terraform for loops
- Azure VM Custom Data and Cloud-init
- Azure VM Extensions
