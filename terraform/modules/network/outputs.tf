output "vnet_name" {
  description = "Nom du réseau virtuel"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  description = "ID du réseau virtuel"
  value       = azurerm_virtual_network.vnet.id
}

output "subnet_ids" {
  description = "IDs des sous-réseaux"
  value       = { for k, v in azurerm_subnet.subnet : k => v.id }
}

output "nsg_ids" {
  description = "IDs des Network Security Groups"
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.id }
}
