variable "rg_name" {
  description = "Nom du resource group"
  type        = string
}

variable "vnet_name" {
  description = "Nom du Virtual Network"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
  default     = "francecentral"
}

variable "address_space" {
  description = "Adresse IP du VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Liste de subnets à créer avec NSG associé"
  type = list(object({
    name       = string
    prefix     = string
    nsg_name   = string
  }))
  default = [
    {
      name     = "subnet-web"
      prefix   = "10.0.1.0/24"
      nsg_name = "nsg-web"
    }
  ]
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default     = {}
}
