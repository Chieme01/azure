data "azurerm_subscription" "current" {}

# data "azurerm_resource_group" "existing_rg" {
#   name = "learndevops"
# }

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name_prefix}-Vnet"
  address_space       = var.vnet_address_space
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "privateSubnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_addresses.private_subnet_address_prefixes
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "publicSubnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_addresses.public_subnet_address_prefixes
  default_outbound_access_enabled = true
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.resource_group_name_prefix}-subnet-NSG"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
}

resource "azurerm_network_security_rule" "nsg_rule" {
  name                        = "AllowAllOutbound"
  priority                    = 140
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_security_rule" "inbound_nsg_rule_2" {
  name                        = "AllowVNet"
  priority                    = 160
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22", "80", "443", "3389"]
  source_address_prefix       = var.vnet_address_space[0]  #tolist(azurerm_virtual_network.vnet.address_space)[0]
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "inbound_nsg_rule_k8" {
  name                        = "K8ports"
  priority                    = 170
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["6443", "10250", "10256", "10257", "10259", "2379-2380", "30000-32767"]
  source_address_prefix       = var.vnet_address_space[0] #tolist(azurerm_virtual_network.vnet.address_space)[0]
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}