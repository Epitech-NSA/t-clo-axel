output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.this.name
}

output "primary_access_key" {
  description = "Primary access key for storage account"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "container_name" {
  description = "Storage container name for tfstate"
  value       = azurerm_storage_container.tfstate.name
}

output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.this.id
}


