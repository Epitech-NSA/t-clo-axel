output "rg_name" {
  description = "Nom du resource group"
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Localisation du resource group"
  value       = azurerm_resource_group.this.location
}

output "rg_id" {
  description = "ID du resource group"
  value       = azurerm_resource_group.this.id
}
