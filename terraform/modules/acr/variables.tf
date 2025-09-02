variable "rg_name" { type = string }
variable "acr_name" { type = string }
variable "location" { type = string }
variable "sku" { 
    type = string
    default = "Basic"
}
variable "tags" {
  type    = map(string)
  default = {}
}
