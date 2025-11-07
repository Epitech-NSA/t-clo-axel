variable "rg_name" {
  description = "Nom du resource group"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
}

variable "mysql_server_name" {
  description = "Nom du serveur MySQL"
  type        = string
}

variable "admin_username" {
  description = "Nom d'utilisateur administrateur MySQL"
  type        = string
  default     = "app_admin"
}

variable "admin_password" {
  description = "Mot de passe administrateur MySQL"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "app_database"
}

variable "sku_name" {
  description = "SKU du serveur MySQL (ex: B_Standard_B1ms pour Burstable, GP_Standard_D2s_v3 pour General Purpose)"
  type        = string
  default     = "B_Standard_B1ms"  
  
  validation {
    condition = can(regex("^(B_Standard_B[1-9]ms|GP_Standard_.*|MO_Standard_.*)$", var.sku_name))
    error_message = "Le SKU doit être un SKU valide Azure MySQL Flexible Server (Burstable: B_Standard_B1ms, B_Standard_B2s, etc.)"
  }
}

variable "storage_gb" {
  description = "Taille de stockage en GB"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags pour les ressources"
  type        = map(string)
  default     = {}
}
