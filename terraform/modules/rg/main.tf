# Data source pour récupérer le RG existant (fourni par Epitech)
data "azurerm_resource_group" "this" {
  name = var.rg_name
}
