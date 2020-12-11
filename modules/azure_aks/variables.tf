variable "name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "client_id" {
  description = "Service principal id"
  type        = string
}

variable "client_secret" {
  description = "Service principal password"
  type        = string
}

variable "container_registry_id" {
  description = "Resource id of the ACR"
  type        = string
}

variable "control_plane_kubernetes_version" {
  description = "Kubernetes version of control plane"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the AKS cluster resource group"
  type        = string
}

variable "location" {
  description = "Azure region of the AKS cluster"
  type        = string
}

variable "vnet_subnet_id" {
  description = "Resource id of the Virtual Network subnet"
  type        = string
}

variable "private_cluster" {
  description = "Deploy an AKS cluster without a public accessible API endpoint."
  type        = bool
}

variable "sla_sku" {
  description = "Define the SLA under which the managed master control plane of AKS is running."
  type        = string
  default     = "Free"
}

variable "api_auth_ips" {
  description = "Whitelist of IP addresses to access control plane"
  type        = list(string)
}

variable "default_node_pool" {
  description = "The object to configure the default node pool with number of worker nodes, worker node VM size and Availability Zones."
  type = object({
    name       = string
    vm_size    = string
  })
}

variable "enable_blue_pool" {
  default = false
  type    = bool
}

variable "enable_green_pool" {
  default = false
  type    = bool
}

variable "drain_blue_pool" {
  default = false
  type    = bool
}

variable "drain_green_pool" {
  default = false
  type    = bool
}

variable "blue_pool" {
  description = "Definition for Blue System Pool"
  type = object ({
    name                           = string 
    system_min_count               = number
    system_max_count               = number
    user_min_count                 = number
    user_max_count                 = number
    system_vm_size                 = string
    user_vm_size                   = string 
    system_disk_size               = number 
    user_disk_size                 = number
    zones                          = list(string)
    node_os                        = string
    azure_tags                     = map(string)
    pool_kubernetes_version        = string
  })
}

variable "green_pool" {
  description = "Definition for Green System Pool"
  type = object ({
    name                           = string 
    system_min_count               = number
    system_max_count               = number
    user_min_count                 = number
    user_max_count                 = number
    system_vm_size                 = string
    user_vm_size                   = string
    system_disk_size               = number 
    user_disk_size                 = number 
    zones                          = list(string)
    node_os                        = string
    azure_tags                     = map(string)
    pool_kubernetes_version        = string
  })
}

variable "addons" {
  description = "Defines which addons will be activated."
  type = object({
    oms_agent             = bool
    kubernetes_dashboard  = bool
    azure_policy          = bool
  })

  default = {
    oms_agent             = false
    kubernetes_dashboard  = false
    azure_policy          = false
  }

}
