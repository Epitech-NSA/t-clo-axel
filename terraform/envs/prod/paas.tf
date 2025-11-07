# PaaS Deployment - App Service (Production)
# Requires: infrastructure.tf (for rg, network, acr, mysql modules)

module "appservice" {
  source = "../../modules/appservice"

  rg_name              = module.rg.rg_name
  location             = module.rg.location
  tags                 = local.common_tags
  appservice_plan_name = "tc-${var.environment}-asp-frc-01"
  sku_name             = var.app_service_sku

  webapp_name          = "tc-${var.environment}-web-frc-01"

  acr_login_server     = module.acr.login_server
  acr_id               = module.acr.acr_id
  acr_admin_username   = module.acr.admin_username
  acr_admin_password   = module.acr.admin_password
  image_name           = "sample-app"
  image_tag            = "latest"
  app_source_path      = "../../../sample-app-master"

  mysql_fqdn              = module.mysql.mysql_fqdn
  database_name           = module.mysql.database_name
  mysql_admin_username    = module.mysql.admin_username
  mysql_admin_password    = var.mysql_admin_password
  
  app_debug               = "false"  # Production should never have debug enabled
  app_env                 = var.environment
}

# PaaS Outputs
output "webapp_url" {
  description = "URL de l'application web déployée"
  value       = "https://${module.appservice.webapp_url}"
}
