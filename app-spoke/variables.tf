variable "prefix" {
  type                      = string
  default                   = "terra-gaf"
  description               = "A prefix used for all resources"
}

variable "location" {
  type                      = string
  default                   = "eastus"
  description               = "The Azure Region used"
}

variable "active_backend_pool" {
  description = "which backend to activate via the app gateway"
  type        = string 
  validation {
    condition     = (var.active_backend_pool == "blue" || var.active_backend_pool == "green")
    error_message = "Must be one of blue or green."
  }
  default     = "blue"
}

variable "enable_blue_pool" {
  type = bool 
  description = "whether or not a blue pool exists"
}

variable "enable_green_pool" {
  type = bool 
  description = "whether or not a green pool exists"
}

variable "drain_green_pool" {
  type = bool 
  description = "whether or not to taint the green pool to drain pods from it"
}

variable "drain_blue_pool" {
  type = bool 
  description = "whether or not to taint the blue pool to drain pods from it"
}

variable "az_sp_app_id" {
  type = string
  description = "Azure service principal app id"
}

variable "az_sp_password" {
  type = string
  description = "Azure service principal secret"
}

variable "app_rg" {
  type = string
  description = "Resource Group for application"
}

variable "app_vnet_name" {
  type                      = string
  description               = "Name of the application vnet"
}

variable "firewall_private_ip" {
  type                      = string
  description               = "IP of Firewall for use in application route table"
}
