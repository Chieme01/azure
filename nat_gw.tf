resource "azurerm_nat_gateway" "nat_gw" {
  name                    = "${var.resource_group_name_prefix}-nat-Gateway"
  location                = local.resource_group_location
  resource_group_name     = local.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.nat_gw_idle_timeout
 }

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.resource_group_name_prefix}-natgw-public-ip"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  allocation_method   = var.pip_allocation
  sku                 = var.natgw_pip_sku
}

resource "azurerm_nat_gateway_public_ip_association" "pip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.public_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_gw_association" {
  subnet_id      = azurerm_subnet.public_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}
