/* resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}
 */

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "${var.resource_group_name_prefix}-rg"
} 

locals {
  resource_group_name = azurerm_resource_group.rg.name
  resource_group_location = azurerm_resource_group.rg.location
}
