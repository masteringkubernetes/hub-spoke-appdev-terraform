variable "hub-vnet-name" {
  type                      = string
  default                   = "vnet-hub"
  description               = "Hub VNet Name"
}

variable "hub-vnet-rg" {
  type                      = string
  default                   = "HUB-RG"
  description               = "Hub Resource Group Name"
}

variable "prefix" {
  type                      = string
  default                   = "terra"
  description               = "A prefix used for all resources"
}

variable "location" {
  type                      = string
  default                   = "eastus"
  description               = "The Azure Region used"
}

