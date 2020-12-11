variable resource_group_name {
  description = "Resource Group name"
  type        = string
}

variable location {
  description = "Location in which to deploy the network"
  type        = string
}

variable vnet_name {
  description = "VNET name"
  type        = string
}

variable address_space {
  description = "VNET address space"
  type        = list(string)
}

variable tags {
  description = "Tags to apply to resources"
  default     = null
}

# This is only used for the defaults.  Use subnet below to interact with this module
variable subnets {
  type = list(
    object({
      name                            = string
      address_prefixes                = list(string)
      private_link_endpoint_policies_enforced  = bool 
      private_link_service_policies_enforced  = bool 
    })
  )
}