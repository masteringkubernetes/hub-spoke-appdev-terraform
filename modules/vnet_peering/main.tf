resource "azurerm_virtual_network_peering" "peering" {
  name                      = var.peering_name_1_to_2
  resource_group_name       = var.vnet_1_rg
  virtual_network_name      = var.vnet_1_name
  remote_virtual_network_id = var.vnet_2_id
  allow_gateway_transit     = var.vnet1_network_gateway ? true : false 
  use_remote_gateways       = var.vnet1_use_remote_gateway ? true : false 
}

resource "azurerm_virtual_network_peering" "peering-back" {
  name                      = var.peering_name_2_to_1
  resource_group_name       = var.vnet_2_rg
  virtual_network_name      = var.vnet_2_name
  remote_virtual_network_id = var.vnet_1_id
  allow_gateway_transit     = var.vnet2_network_gateway ? true : false 
  use_remote_gateways       = var.vnet2_use_remote_gateway ? true : false 
}