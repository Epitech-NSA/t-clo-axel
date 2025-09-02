# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = var.address_space
  tags                = var.tags
}

# Network Security Groups (NSG)
resource "azurerm_network_security_group" "nsg" {
  for_each            = { for s in var.subnets : s.nsg_name => s }
  name                = each.value.nsg_name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "subnet" {
  for_each            = { for s in var.subnets : s.name => s }
  name                 = each.value.name
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.prefix]
}

# Association Subnet ↔ NSG
resource "azurerm_subnet_network_security_group_association" "assoc" {
  for_each = { for s in var.subnets : s.name => s }

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg_name].id
}
