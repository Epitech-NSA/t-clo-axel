variable "vmss_name" {
  description = "Name of the Virtual Machine Scale Set"
  type        = string
}

variable "rg_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where the VMSS will be deployed"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for authentication"
  type        = string
}

variable "vm_sku" {
  description = "SKU/size of the VMs in the scale set"
  type        = string
  default     = "Standard_B2s"
}

variable "initial_instance_count" {
  description = "Initial number of VM instances"
  type        = number
  default     = 2
}

variable "min_instance_count" {
  description = "Minimum number of VM instances for auto-scaling"
  type        = number
  default     = 2
}

variable "max_instance_count" {
  description = "Maximum number of VM instances for auto-scaling"
  type        = number
  default     = 5
}

variable "subnet_id" {
  description = "ID of the subnet where VMs will be deployed"
  type        = string
}

variable "lb_backend_pool_id" {
  description = "ID of the Load Balancer backend pool"
  type        = string
}

variable "lb_nat_pool_id" {
  description = "ID of the Load Balancer NAT pool for SSH access"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the VMSS resources"
  type        = map(string)
  default     = {}
}

