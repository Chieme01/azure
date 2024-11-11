locals {
  bastion_sku = var.bastion_host_sku
  developer_bastion_host_name = join("-", [azurerm_virtual_network.vnet.name ,"developer-bastion"])
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_addresses.bastion_subnet_address_prefixes
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.resource_group_name_prefix}-bastion-public-ip"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  allocation_method   = var.pip_allocation
  sku                 = var.bastion_pip_sku
}

resource "azurerm_bastion_host" "developer_bastion_host" {
  count               = local.bastion_sku == "Developer" ? 1 : 0
  name                = local.developer_bastion_host_name
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  sku                 = local.bastion_sku
  virtual_network_id  = azurerm_virtual_network.vnet.id
}

resource "azurerm_bastion_host" "bastion_host" {
  count               = local.bastion_sku != "Developer" ? 1 : 0
  name                = join("-", [azurerm_virtual_network.vnet.name ,"bastion"])
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  sku                 = local.bastion_sku

    ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

output "bastion_pip" {
  value = local.bastion_sku == "Developer" ? "No public IP. SKU is Developer" : azurerm_bastion_host.bastion_host[0].ip_configuration[0].public_ip_address_id
}