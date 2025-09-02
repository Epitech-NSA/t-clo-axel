output "webapp_name" {
  description = "Nom de l'application web"
  value       = azurerm_linux_web_app.this.name
}

output "webapp_url" {
  description = "URL de l'application web (nom seulement, sans https://)"
  value       = azurerm_linux_web_app.this.default_hostname
}

output "webapp_id" {
  description = "ID de l'application web"
  value       = azurerm_linux_web_app.this.id
}

output "app_service_plan_id" {
  description = "ID du plan App Service"
  value       = azurerm_service_plan.this.id
}
