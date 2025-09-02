locals {
  common_tags = {
    project       = "TERRACLOUD"
    env           = "dev"
    owner         = "etu-epitech"
    subscription  = "6b9318b1-2215-418a-b0fd-ba0832e9b333"
    shutdownPolicy = "19:00-08:00"
  }
}

provider "azurerm" {
  subscription_id = "6b9318b1-2215-418a-b0fd-ba0832e9b333"
  features {}
}

module "rg" {
  source   = "../../modules/rg"
  rg_name  = "rg-nan_1"
  location = "francecentral"
  tags     = local.common_tags
}

module "network" {
  source    = "../../modules/network"
  rg_name   = module.rg.rg_name
  vnet_name = "tc-dev-vnet-frc-01"
  location  = "francecentral"
  subnets = [
    {
      name     = "subnet-web"
      prefix   = "10.0.1.0/24"
      nsg_name = "nsg-web"
    },
    {
      name     = "subnet-app"
      prefix   = "10.0.2.0/24"
      nsg_name = "nsg-app"
    }
  ]
  tags = local.common_tags
}

module "acr" {
  source   = "../../modules/acr"
  rg_name  = module.rg.rg_name
  acr_name = "tcdevacrfrc01"
  location = "francecentral"
  tags     = local.common_tags
}

# module "mysql" {
#   source = "../../modules/mysql"

#   rg_name            = module.rg.rg_name
#   location           = module.rg.location
#   mysql_server_name  = "tc-dev-mysql-frc-01"
#   admin_username     = "app_admin"
#   admin_password     = "SecurePassword123!" 
#   database_name      = "app_database"
#   tags               = local.common_tags
# }

module "appservice" {
  source = "../../modules/appservice"

  rg_name              = module.rg.rg_name
  location             = module.rg.location
  tags                 = local.common_tags
  appservice_plan_name = "tc-dev-asp-frc-01"
  sku_name             = "B1"

  webapp_name          = "tc-dev-web-frc-01"

  acr_login_server     = module.acr.login_server
  acr_id               = module.acr.acr_id
  acr_admin_username   = module.acr.admin_username
  acr_admin_password   = module.acr.admin_password
  image_name           = "sample-app"
  image_tag            = "latest"
  app_source_path      = "/home/axel/Epitech/T-CLO-900/sample-app-master"

  mysql_fqdn              = "module.mysql.mysql_fqdn"
  database_name           = "module.mysql.database_name"
  mysql_admin_username    = "module.mysql.admin_username"
  mysql_admin_password    = "SecurePassword123!" 
}

output "webapp_url" {
  description = "URL de l'application web déployée"
  value       = "https://${module.appservice.webapp_url}"
}

# output "mysql_info" {
#   description = "Informations de connexion MySQL"
#   value = {
#     server_name = module.mysql.mysql_server_name
#     fqdn        = module.mysql.mysql_fqdn
#     database    = module.mysql.database_name
#     username    = module.mysql.admin_username
#   }
#   sensitive = false
# }

