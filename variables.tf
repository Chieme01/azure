variable "subscription_id" {}

variable "tenant_id" {}

variable "resource_group_location" {
  type        = string
  default     = "westus"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "k8-devops"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "azureuser"
}

variable "vm_pip_sku" {
  default      = "Basic"
  description = "The SKU of the Public IP of Virtual Machines. Accepted values are Basic and Standard"
  type        = string
}

variable "source_image_reference" {
  description = "Source image reference for the virtual machine"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

variable "master_vm_size" {
  type = string
  default = "Standard_D2s_v3"
}

variable "worker_vm_size" {
  type = string
  default = "Standard_B2s" #Standard_B2s #Standard_B1s
}

variable "spot_instance" {
  description = "Set to true to use spot instances. Set to false to use on demand"
  default = {
    master_spot_instances = false
    worker_spot_instances = false
  }
}

variable "cluster_size" {
  description = "The size of your kubernetes cluster"
  default = {
    num_of_controlplanes = 1
    num_of_workers = 2
  }
}

variable "attach_public_ip" {
  default = false
  description = "Attach a public ip to each vm in the cluster."
}

variable "bastion_host_sku" {
  default = "Basic"
  description = "The SKU of the Bastion Host. Accepted values are Developer, Basic, Standard and Premium"
}

variable "nat_gw_idle_timeout" {
  default = 4
  description = "The idle timeout which should be used in minutes"
}

variable "vnet_address_space" {
  description = "The address space that is used the virtual network. You can supply more than one address space"
  default = ["10.0.0.0/16"]
}

variable "subnet_addresses" {
  description = "The address prefixes to use for the subnet"
  default = {
    private_subnet_address_prefixes = ["10.0.2.0/24"]
    public_subnet_address_prefixes  = ["10.0.3.0/24"]
    bastion_subnet_address_prefixes = ["10.0.4.0/27"]
  }
}

variable "os_disk" {
  description = "caching - The Type of Caching which should be used for the Internal OS Disk. Possible values are None, ReadOnly and ReadWrite. | storage_account_type - The Type of Storage Account which should back this the Internal OS Disk. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS."
  default = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

variable "identity_type" {
  default = "SystemAssigned"
  description = "Specifies the type of Managed Service Identity that should be configured on this Linux Virtual Machine. Possible values are SystemAssigned, UserAssigned, SystemAssigned, UserAssigned (to enable both)."
}

variable "pip_allocation" {
  default = "Static"
}

variable "bastion_pip_sku" {
  description = "The SKU of the Public IP of bastion host. Accepted values are Basic and Standard"
  default = "Standard"
}

variable "natgw_pip_sku" {
  description = "The SKU of the Public IP of NAT Gateway. Accepted values are Basic and Standard"
  default = "Standard"
}

variable "common_tags" {
  default = {
    environment = "dev"
  }
}