variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "francecentral"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "6b9318b1-2215-418a-b0fd-ba0832e9b333"
}

variable "mysql_admin_password" {
  description = "MySQL administrator password"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_iaas" {
  description = "SSH public key for VMSS instances (IaaS)"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICkWWaahsTfBH/uNumIr9PKJltm/ZLgKCCGEvyTJ1Htc your_email@example.com"
}

variable "app_service_sku" {
  description = "SKU for App Service Plan"
  type        = string
  default     = "B1"
}

variable "mysql_sku" {
  description = "SKU for MySQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "vm_sku" {
  description = "SKU for Virtual Machines in VMSS"
  type        = string
  default     = "Standard_B2s"
}

# Production environments run 24/7, no shutdown policy
# But as it is a school project and asked by Epitech, there is policy
variable "shutdown_policy" {
  description = "Shutdown policy for VMs (empty for production - runs 24/7)"
  type        = string
  default     = "19:00-08:00"
}

