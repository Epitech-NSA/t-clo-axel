# Backend configuration for Terraform state
# Uncomment and configure if using Azure Storage backend

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state"
#     storage_account_name = "sttfstateprod01"
#     container_name       = "tfstate"
#     key                  = "prod.terraform.tfstate"
#   }
# }

# For local backend, state is stored in terraform.tfstate file
# Make sure to add *.tfstate to .gitignore

