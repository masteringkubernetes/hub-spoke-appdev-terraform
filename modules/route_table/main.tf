resource "azurerm_route_table" "rt" {
  #Added ignore to route table because AKS makes changes to this
  #This doesn't necessarily have to be here because AKS will add
  #them back in if Terraform removes them, HOWEVER when Terraform
  #runs there will be some amount of seconds where the routes change
  #and will impact incoming/outgoing traffic.
  lifecycle {
    ignore_changes = ["route"]
  }
  name                = var.rt_name
  tags                = var.tags
  location            = var.location
  resource_group_name = var.resource_group

  route {
    name                   = "kubenetfw_fw_r"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "aks_subnet_association" {
  subnet_id      = var.subnet_id
  route_table_id = azurerm_route_table.rt.id
}