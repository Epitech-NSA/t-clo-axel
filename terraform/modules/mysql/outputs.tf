output "mysql_server_name" {
  description = "Nom du serveur MySQL"
  value       = azurerm_mysql_flexible_server.this.name
}

output "mysql_fqdn" {
  description = "FQDN du serveur MySQL"
  value       = azurerm_mysql_flexible_server.this.fqdn
}

output "database_name" {
  description = "Nom de la base de données"
  value       = azurerm_mysql_flexible_database.this.name
}

output "admin_username" {
  description = "Nom d'utilisateur administrateur"
  value       = azurerm_mysql_flexible_server.this.administrator_login
}

output "connection_string" {
  description = "Chaîne de connexion MySQL"
  value       = "Server=${azurerm_mysql_flexible_server.this.fqdn};Database=${azurerm_mysql_flexible_database.this.name};Uid=${azurerm_mysql_flexible_server.this.administrator_login};"
  sensitive   = true
}
