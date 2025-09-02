resource "azurerm_mysql_flexible_server" "this" {
  name                   = var.mysql_server_name
  resource_group_name    = var.rg_name
  location               = var.location
  
  administrator_login    = var.admin_username
  administrator_password = var.admin_password
  
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false
  
  sku_name = var.sku_name
  version  = "8.0.21"
  
  storage {
    auto_grow_enabled = true
    size_gb          = var.storage_gb
  }

  tags = var.tags
}

resource "azurerm_mysql_flexible_database" "this" {
  name                = var.database_name
  resource_group_name = var.rg_name
  server_name         = azurerm_mysql_flexible_server.this.name
  charset             = "utf8mb4"
  collation          = "utf8mb4_unicode_ci"
}

# Règle de firewall pour permettre l'accès depuis Azure services
resource "azurerm_mysql_flexible_server_firewall_rule" "azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = var.rg_name
  server_name         = azurerm_mysql_flexible_server.this.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Configuration pour VNET si nécessaire
resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  name                = "require_secure_transport"
  resource_group_name = var.rg_name
  server_name         = azurerm_mysql_flexible_server.this.name
  value               = "OFF"  # utiliser ON en prod
}
