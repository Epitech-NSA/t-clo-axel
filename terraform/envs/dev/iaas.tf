# IaaS Deployment - VMSS with Load Balancer
# Requires: infrastructure.tf (for rg, network, acr, mysql modules)

locals {
  iaas_common_tags = {
    project             = "TERRACLOUD"
    env                 = var.environment
    owner               = "etu-epitech"
    subscription        = var.subscription_id
    shutdownPolicy      = var.shutdown_policy
    managedBy           = "terraform"
    tenant              = "Epitech"
    cost_center         = "nan_1"
    data_classification = "internal"
    criticality         = "low"
    deployment_type     = "IaaS"
  }
}

# Load Balancer
module "loadbalancer" {
  source             = "../../modules/loadbalancer"
  lb_name            = "tc-${var.environment}-lb-frc-01"
  pip_name           = "tc-${var.environment}-pip-frc-01"
  location           = var.location
  rg_name            = module.rg.rg_name
  backend_pool_name  = "vmss-backend-pool"
  tags               = local.iaas_common_tags
}

# Virtual Machine Scale Set
module "vmss" {
  source                 = "../../modules/vmss"
  vmss_name              = "tc-${var.environment}-vmss-frc-01"
  rg_name                = module.rg.rg_name
  location               = var.location
  admin_username         = "azureuser"
  ssh_public_key         = var.ssh_public_key_iaas
  vm_sku                 = var.vm_sku
  initial_instance_count = 2
  min_instance_count     = 2
  max_instance_count     = 5
  subnet_id              = module.network.subnet_ids["subnet-vmss"]
  lb_backend_pool_id     = module.loadbalancer.backend_pool_id
  lb_nat_pool_id         = module.loadbalancer.nat_pool_id
  tags                   = local.iaas_common_tags
}

# Grant AcrPull role to VMSS managed identity
resource "azurerm_role_assignment" "vmss_acr_pull" {
  scope                = module.acr.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.vmss.principal_id
}

# Firewall rule to allow VMSS subnet to access MySQL
resource "azurerm_mysql_flexible_server_firewall_rule" "vmss_to_mysql" {
  name                = "AllowVMSSSubnet"
  resource_group_name = module.rg.rg_name
  server_name         = module.mysql.mysql_server_name
  start_ip_address    = "10.0.3.0"
  end_ip_address      = "10.0.3.255"
}

# IaaS Outputs
output "iaas_load_balancer_ip" {
  description = "Public IP address of the Load Balancer"
  value       = module.loadbalancer.public_ip_address
}

output "iaas_vmss_name" {
  description = "Name of the Virtual Machine Scale Set"
  value       = module.vmss.vmss_name
}

output "iaas_vmss_id" {
  description = "ID of the Virtual Machine Scale Set"
  value       = module.vmss.vmss_id
}

output "iaas_access_info" {
  description = "Access information for IaaS deployment"
  value = {
    load_balancer_ip = module.loadbalancer.public_ip_address
    vmss_name        = module.vmss.vmss_name
    ssh_command      = "ssh -p 50000 azureuser@${module.loadbalancer.public_ip_address}"
    mysql_fqdn       = module.mysql.mysql_fqdn
    acr_login_server = module.acr.login_server
  }
}
