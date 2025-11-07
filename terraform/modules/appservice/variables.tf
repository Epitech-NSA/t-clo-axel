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

variable "acr_id" {
  description = "ID du Azure Container Registry"
  type        = string
}

variable "image_name" {
  description = "Nom de l'image Docker"
}

variable "image_tag" {
  description = "Tag de l'image Docker"
}

variable "app_source_path" {
  description = "Chemin vers le code source de l'application (contenant le Dockerfile)"
  type        = string
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
