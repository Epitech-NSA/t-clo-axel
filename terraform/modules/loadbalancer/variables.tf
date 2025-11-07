variable "lb_name" {
  description = "Name of the Azure Load Balancer"
  type        = string
}

variable "pip_name" {
  description = "Name of the Public IP for the Load Balancer"
  type        = string
}

variable "location" {
  description = "Azure region where the Load Balancer will be deployed"
  type        = string
}

variable "rg_name" {
  description = "Name of the resource group"
  type        = string
}

variable "backend_pool_name" {
  description = "Name of the backend address pool"
  type        = string
  default     = "vmss-backend-pool"
}

variable "tags" {
  description = "Tags to apply to the Load Balancer resources"
  type        = map(string)
  default     = {}
}

