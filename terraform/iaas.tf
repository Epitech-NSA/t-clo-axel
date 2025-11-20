# IaaS Deployment - VMSS with Public IP
# Requires: main.tf (for rg, network, acr, mysql modules)

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
    criticality         = var.environment == "prod" ? "medium" : "low"
    deployment_type     = "IaaS"
  }
}

# Virtual Machine Scale Set
# Public IPs are automatically assigned to each instance
module "vmss" {
  source                 = "./modules/vmss"
  vmss_name              = "tc-${var.environment}-vmss-frc-01"
  rg_name                = module.rg.rg_name
  location               = var.location
  admin_username         = "azureuser"
  ssh_public_key         = var.ssh_public_key_iaas
  vm_sku                 = var.vm_sku
  initial_instance_count = var.environment == "prod" ? 2 : 1
  min_instance_count     = var.environment == "prod" ? 2 : 1
  max_instance_count     = var.environment == "prod" ? 5 : 2
  subnet_id              = module.network.subnet_ids["subnet-vmss"]
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
  start_ip_address    = var.environment == "prod" ? "10.1.3.0" : "10.0.3.0"
  end_ip_address      = var.environment == "prod" ? "10.1.3.255" : "10.0.3.255"
}

