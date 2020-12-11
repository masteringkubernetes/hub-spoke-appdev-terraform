variable "name" {
  description     = "Name of app gateway"
  type            = string
  default         = "app-gw"
}

variable "resource_group" {
  description     = "Resource group where app gateway will be created"
  type            = string    
}

variable "location" {
  description     = "Region where app gateway will be created"
  type            = string
  default         = "eastus"
}

variable "tags" {
  description = "Tags to apply to resources"
  default     = null
}

variable "subnet_id" {
  description = "Gateway subnet id"
  type        = string 
}

variable "blue_backend_ip_addresses" {
  description = "blue backend ip addresses for pool"
  type        = list(string)
  default     = null
}

variable "green_backend_ip_addresses" {
  description = "green backend ip addresses for pool"
  type        = list(string)
  default     = null
}

variable "identity_ids" {
  description = "user assigned identity for app gateway"
  type        = list(string)
  default     = null
}

variable "active_backend" {
  description = "which backend to activate via the app gateway"
  type        = string 
  validation {
    condition     = (var.active_backend == "blue" || var.active_backend == "green")
    error_message = "Must be one of blue or green."
  }
}