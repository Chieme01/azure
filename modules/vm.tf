data "azurerm_role_definition" "roles" {
  for_each = toset(local.roles_to_fetch)
  name     = each.value
}

locals {
  spot_instance     = var.spot_instance.master_spot_instances
  priority          = local.spot_instance ? "Spot" : "Regular"
  num_of_masters    = var.cluster_size.num_of_controlplanes
  num_of_workers    = var.cluster_size.num_of_workers
  cluster_size      = local.num_of_masters + local.num_of_workers
  attach_public_ip  = var.attach_public_ip

# Terraform Service Principal's permissions has a conditional constraint on roles it can assign.
# Ensure that roles to be assigned are included in the service Principal's conditions.
# Go to the Scope(usually subscription) -> Access Control -> Role Assignments -> View/Edit -> Constrain roles -> Configure
  roles_to_fetch = ["Monitoring Metrics Publisher", "Key Vault Secrets Officer", "Log Analytics Contributor", "Storage Blob Data Contributor"]

  vm_to_roles = [ 
    data.azurerm_role_definition.roles["Key Vault Secrets Officer"],
    data.azurerm_role_definition.roles["Monitoring Metrics Publisher"],
    data.azurerm_role_definition.roles["Storage Blob Data Contributor"]
  ]


  role_assignments = flatten([
    for vm in local.linux_virtual_machines : [
      for role in local.vm_to_roles : {
        vm_name       = vm.name
        vm_function   = vm.node_type
        role_name     = role.name
      }
    ]
  ])

  master_nodes = {
    for i in range(local.num_of_masters): "master-node-${i}" => {
      name                  = "master-node-${i}"
      size                  = var.master_vm_size
      computer_name         = "master-node-${i}"
      priority              = local.priority
      eviction_policy       = local.spot_instance ? "Deallocate" : null
      custom_data           = data.template_cloudinit_config.masterconfig.rendered
      tags                  = merge(var.common_tags, var.workernode_tags)
      node_type             = "master_nodes"
    }
  }

  worker_nodes = {
    for i in range(local.num_of_workers): "worker-node-${i}" => {
      name                  = "worker-node-${i}"
      size                  = var.worker_vm_size
      computer_name         = "worker-node-${i}"
      priority              = local.priority
      eviction_policy       = local.spot_instance ? "Deallocate" : null
      custom_data           = null #data.template_cloudinit_config.workerconfig.rendered
      tags                  = merge(var.common_tags, var.workernode_tags)
      node_type             = "worker_nodes"
    }
  }
  
  linux_virtual_machines = merge(local.worker_nodes, local.master_nodes)
}

resource "azurerm_role_assignment" "all_assignments" {
  for_each              = {for pair in local.role_assignments : "${pair.vm_name}+${pair.role_name}" => pair}
  scope                 = azurerm_resource_group.rg.id
  role_definition_name  = each.value.role_name
  principal_id          = azurerm_linux_virtual_machine.all_nodes[each.value.vm_name].identity[0].principal_id
}

resource "azurerm_network_interface" "nic" {
  for_each            = local.linux_virtual_machines
  #count               = local.cluster_size
  name                = join("-", ["vmNic", each.value.name])
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = local.attach_public_ip ? azurerm_public_ip.vm_pip[each.key].id : null
  }
}

resource "azurerm_linux_virtual_machine" "all_nodes" {
  #count                 = local.num_of_masters
  for_each              = local.linux_virtual_machines
  name                  = each.value.name
  resource_group_name   = local.resource_group_name
  location              = local.resource_group_location
  size                  = each.value.size
  network_interface_ids = [ azurerm_network_interface.nic[each.key].id, ]

  computer_name  = each.value.computer_name
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

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.k8-devops-sa.primary_blob_endpoint
  }

  priority        = each.value.priority
  eviction_policy = each.value.eviction_policy
  #max_bid_price  = 0.01557
  custom_data     = each.value.custom_data
  tags            = each.value.tags
}

data "template_cloudinit_config" "workerconfig" {
  base64_encode = true
  part {
    content = file("${path.module}/scripts/cloud-init-worker.txt")
  }
}

data "template_cloudinit_config" "masterconfig" {
  base64_encode = true
  gzip          = true
  
  part {
    filename      = "install_k8s.sh"
    content_type  = "text/x-shellscript"
    content       = templatefile("${path.module}/scripts/bootstrap-kubernetes.sh", var.cluster_config)
  }

  # part {
  #   content_type = "text/cloud-config" # Tells Azure this is YAML
  #   content = file("${path.module}/cloud-init-master.yaml")
  #   filename     = "init.cfg" # A label for that section of the cloud-init payload
  # }

}

resource "azurerm_public_ip" "vm_pip" {
  for_each            = local.attach_public_ip ? local.linux_virtual_machines : {}
  name                = join("-", ["vm-public-Ip", each.value.name])
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
  for_each              = var.deploy_extension ? local.master_nodes : {}
  name                 = "k8-bootstrap-extension"
  virtual_machine_id   = azurerm_linux_virtual_machine.all_nodes[each.value.name].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
 {
  "commandToExecute": "KUBEJOIN=$(sudo kubeadm token create --print-join-command) && az login --identity && az keyvault secret set --vault-name \"nyonK8sKeyVault2\" --name \"kubejoin\" --value \"$KUBEJOIN\""
 }
SETTINGS

  tags                = var.common_tags
  #depends_on          = [ azurerm_linux_virtual_machine.all_nodes ]
}
