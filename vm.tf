locals {
  spot_instance     = var.spot_instance.master_spot_instances
  priority          = local.spot_instance ? "Spot" : "Regular"
  num_of_masters    = var.cluster_size.num_of_controlplanes
  num_of_workers    = var.cluster_size.num_of_workers
  cluster_size      = local.num_of_masters + local.num_of_workers
  attach_public_ip  = var.attach_public_ip
}

resource "azurerm_network_interface" "nic" {
  count               = local.cluster_size
  name                = join("-", ["vmNic", count.index])
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = local.attach_public_ip ? azurerm_public_ip.vm_pip[count.index].id : null
  }
}

resource "azurerm_linux_virtual_machine" "masternode" {
  count                 = local.num_of_masters
  name                  = join("-", ["master-node", count.index]) #"masternode"
  resource_group_name   = local.resource_group_name
  location              = local.resource_group_location
  size                  = var.master_vm_size
  network_interface_ids = [
    azurerm_network_interface.nic[local.num_of_workers].id,
  ]

  computer_name  = join("-", ["master-node", count.index])
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }

  identity {
    type = var.identity_type
  }

  os_disk {
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  priority        = local.priority
  eviction_policy = local.spot_instance ? "Deallocate" : null
  #max_bid_price  = 0.01557
  custom_data     = data.template_cloudinit_config.masterconfig.rendered
  user_data       = filebase64("./script.sh")
}

resource "azurerm_linux_virtual_machine" "worker_nodes" {
  count               = local.num_of_workers
  name                = join("-", ["worker-node", count.index])
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  size                = var.worker_vm_size
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  computer_name  = join("-", ["worker-node", count.index])
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }

  identity {
    type = var.identity_type
  }

  os_disk {
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  custom_data = data.template_cloudinit_config.config.rendered
}

resource "azurerm_role_assignment" "role_assignment" {
  count                 = local.num_of_masters 
  scope                 = azurerm_key_vault.key_vault.id
  role_definition_name  = "Key Vault Secrets Officer" 
  principal_id          = azurerm_linux_virtual_machine.masternode[count.index].identity[0].principal_id
}

data "template_cloudinit_config" "config" {
  base64_encode = true
  part {
    content = file("cloud-init-worker.txt")
  }
}

data "template_cloudinit_config" "masterconfig" {
  base64_encode = true
  part {
    content = file("cloud-init-master.txt")
  }
}

resource "azurerm_public_ip" "vm_pip" {
  count               = local.attach_public_ip ? local.cluster_size : 0
  name                = join("-", ["vm-public-Ip", count.index])
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  allocation_method   = var.pip_allocation
  sku                 = var.vm_pip_sku
  
  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

resource "azurerm_virtual_machine_extension" "extension_script" {
  count                = var.deploy_extension ? 1 : 0
  name                 = "k8-bootstrap-extension"
  virtual_machine_id   = azurerm_linux_virtual_machine.masternode[0].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
 {
  "commandToExecute": "KUBEJOIN=$(sudo kubeadm token create --print-join-command) && az login --identity && az keyvault secret set --vault-name \"lockkeyvault\" --name \"kubejoin\" --value \"$KUBEJOIN\""
 }
SETTINGS

  tags = var.common_tags
}