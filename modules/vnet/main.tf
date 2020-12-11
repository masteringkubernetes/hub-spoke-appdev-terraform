resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  tags                = var.tags
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "subnet" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                                          = each.key
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = each.value.address_prefixes
  enforce_private_link_endpoint_network_policies = each.value.private_link_endpoint_policies_enforced
  enforce_private_link_service_network_policies = each.value.private_link_service_policies_enforced
}
