variable "rg_name" {
  description = "Nom du resource group"
}

variable "location" {
  description = "Région Azure où déployer l'App Service"
}

variable "tags" {
  type        = map(string)
  description = "Tags standards du projet"
}

variable "appservice_plan_name" {
  description = "Nom du plan App Service"
}

variable "sku_name" {
  default     = "B1"
  description = "SKU/Pricing tier (B1, P1v2, S1...)"
}

variable "webapp_name" {
  description = "Nom de l'application web"
}

variable "acr_login_server" {
  description = "Serveur de connexion à ACR"
}

variable "image_name" {
  description = "Nom de l'image Docker (doit déjà exister dans ACR)"
}

variable "image_tag" {
  description = "Tag de l'image Docker (doit déjà exister dans ACR)"
  default     = "latest"
}

variable "mysql_fqdn" {
  description = "FQDN du serveur MySQL"
  type        = string
}

variable "database_name" {
  description = "Nom de la base de données"
  type        = string
}

variable "mysql_admin_username" {
  description = "Nom d'utilisateur administrateur MySQL"
  type        = string
}

variable "mysql_admin_password" {
  description = "Mot de passe administrateur MySQL"
  type        = string
  sensitive   = true
}

variable "acr_admin_username" {
  description = "Nom d'utilisateur administrateur ACR"
  type        = string
}

variable "acr_admin_password" {
  description = "Mot de passe administrateur ACR"
  type        = string
  sensitive   = true
}

variable "app_debug" {
  description = "Enable debug mode for Laravel application"
  type        = string
  default     = "false"
}

variable "app_env" {
  description = "Application environment (dev, staging, production)"
  type        = string
  default     = "production"
}
