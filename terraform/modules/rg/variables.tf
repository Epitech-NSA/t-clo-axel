variable "rg_name" {
  description = "Nom du Resource Group"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
  default     = "francecentral"
}

variable "tags" {
  description = "Tags à appliquer au RG"
  type        = map(string)
  default     = {}
}
