# Shared Infrastructure for Both PaaS and IaaS
# This file contains common resources used by both deployment approaches

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

locals {
  common_tags = {
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
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

# Resource Group (existant, fourni par Epitech)
module "rg" {
  source  = "../../modules/rg"
  rg_name = "rg-nan_1"
}

# Network with all subnets for both PaaS and IaaS
module "network" {
  source    = "../../modules/network"
  rg_name   = module.rg.rg_name
  vnet_name = "tc-${var.environment}-vnet-frc-01"
  location  = var.location
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
    },
    {
      name     = "subnet-vmss"
      prefix   = "10.0.3.0/24"
      nsg_name = "nsg-vmss"
    }
  ]
  tags = local.common_tags
}

# Azure Container Registry (shared between PaaS and IaaS)
module "acr" {
  source   = "../../modules/acr"
  rg_name  = module.rg.rg_name
  acr_name = "tc${var.environment}acrfrc01"
  location = var.location
  tags     = local.common_tags
}

# MySQL Flexible Server (shared between PaaS and IaaS)
module "mysql" {
  source = "../../modules/mysql"

  rg_name            = module.rg.rg_name
  location           = module.rg.location
  mysql_server_name  = "tc-${var.environment}-mysql-frc-01"
  admin_username     = "app_admin"
  admin_password     = var.mysql_admin_password
  database_name      = "app_database"
  sku_name           = var.mysql_sku
  tags               = local.common_tags
}

# Outputs for shared infrastructure
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

