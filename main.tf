module "k8s-lab" {
    source = "./modules"
    cluster_size        = {
        num_of_controlplanes = 1
        num_of_workers = 0
    }
    master_vm_size =  "Standard_B2s"
    # worker_vm_size = "Standard_B2s" #Standard_B2s #Standard_B1s
    # source_image_reference  = {
    #     publisher = "Canonical"
    #     offer     = "ubuntu-22_04-lts"
    #     sku       = "server-arm64"
    #     version   = "latest"
    # }
    bastion_host_sku = "Developer"
    key_vault_name = "nyonK8sKeyVault2"
    tenant_id = var.tenant_id
    subscription_id = var.subscription_id
}

resource "azurerm_storage_blob" "ansible_file" {
  name                   = "playbook.yaml"
  storage_account_name   = module.k8s-lab.storage_account_name
  storage_container_name = module.k8s-lab.container_name
  type                   = "Block"
  source                 = "${path.module}/ansible/playbook.yml"
}

