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

# NSG Rules for VMSS subnet
resource "azurerm_network_security_rule" "allow_http_inbound" {
  name                        = "AllowHTTPInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = try(azurerm_network_security_group.nsg["nsg-vmss"].name, null)

  count = contains([for s in var.subnets : s.nsg_name], "nsg-vmss") ? 1 : 0
}

resource "azurerm_network_security_rule" "allow_https_inbound" {
  name                        = "AllowHTTPSInbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = try(azurerm_network_security_group.nsg["nsg-vmss"].name, null)

  count = contains([for s in var.subnets : s.nsg_name], "nsg-vmss") ? 1 : 0
}

resource "azurerm_network_security_rule" "allow_ssh_inbound" {
  name                        = "AllowSSHInbound"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = try(azurerm_network_security_group.nsg["nsg-vmss"].name, null)

  count = contains([for s in var.subnets : s.nsg_name], "nsg-vmss") ? 1 : 0
}

resource "azurerm_network_security_rule" "allow_lb_probe_inbound" {
  name                        = "AllowAzureLoadBalancerInbound"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = try(azurerm_network_security_group.nsg["nsg-vmss"].name, null)

  count = contains([for s in var.subnets : s.nsg_name], "nsg-vmss") ? 1 : 0
}

resource "azurerm_network_security_rule" "allow_mysql_outbound" {
  name                        = "AllowMySQLOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = try(azurerm_network_security_group.nsg["nsg-vmss"].name, null)

  count = contains([for s in var.subnets : s.nsg_name], "nsg-vmss") ? 1 : 0
}

resource "azurerm_network_security_rule" "allow_https_outbound" {
  name                        = "AllowHTTPSOutbound"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = var.rg_name
  network_security_group_name = try(azurerm_network_security_group.nsg["nsg-vmss"].name, null)

  count = contains([for s in var.subnets : s.nsg_name], "nsg-vmss") ? 1 : 0
}
