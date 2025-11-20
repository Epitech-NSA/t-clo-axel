# Shared Infrastructure Outputs
output "rg_name" {
  description = "Resource Group name"
  value       = module.rg.rg_name
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = module.network.vnet_name
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.acr.login_server
}

output "mysql_fqdn" {
  description = "MySQL server FQDN"
  value       = module.mysql.mysql_fqdn
}

output "mysql_info" {
  description = "MySQL connection information"
  value = {
    server_name = module.mysql.mysql_server_name
    fqdn        = module.mysql.mysql_fqdn
    database    = module.mysql.database_name
    username    = module.mysql.admin_username
  }
  sensitive = false
}

# PaaS Outputs
output "webapp_url" {
  description = "URL de l'application web déployée (PaaS)"
  value       = "https://${module.appservice.webapp_url}"
}

# IaaS Outputs
output "iaas_vmss_name" {
  description = "Name of the Virtual Machine Scale Set (IaaS)"
  value       = module.vmss.vmss_name
}

output "iaas_vmss_id" {
  description = "ID of the Virtual Machine Scale Set (IaaS)"
  value       = module.vmss.vmss_id
}

output "iaas_access_info" {
  description = "Access information for IaaS deployment"
  value = {
    vmss_name        = module.vmss.vmss_name
    note             = "Public IPs are assigned automatically to each VMSS instance. Use Azure Portal or CLI to get instance IPs."
    mysql_fqdn       = module.mysql.mysql_fqdn
    acr_login_server = module.acr.login_server
    access_command   = "az vmss list-instance-public-ips --resource-group ${module.rg.rg_name} --name ${module.vmss.vmss_name}"
  }
}

