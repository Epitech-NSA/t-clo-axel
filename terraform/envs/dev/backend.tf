terraform {
  backend "azurerm" {
    resource_group_name  = "rg-nan_1"
    storage_account_name = "sttcdevfrc01"
    container_name       = "tfstate"
    key                  = "terracloud/dev/infra.tfstate"
  }
}
