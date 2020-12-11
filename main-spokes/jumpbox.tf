# data "azurerm_virtual_network" "hub-vnet" {
#   name                   = var.hub-vnet-name
#   resource_group_name    = var.hub-vnet-rg
# }

# data "azurerm_subnet" "hub-vnet-default" {
#   name                 = "default"
#   virtual_network_name = var.hub-vnet-name
#   resource_group_name  = var.hub-vnet-rg
# }

# module "jumpbox" {
#   source                  = "../modules/jumpbox"
#   tags                    = local.tags
#   location                = local.location
#   resource_group          = azurerm_resource_group.app-rg.name 
#   vnet_id                 = data.azurerm_virtual_network.hub-vnet.id
#   subnet_id               = data.azurerm_subnet.hub-vnet-default.id
#   dns_zone_name           = join(".", slice(split(".", module.azure_aks.private_fqdn), 1, length(split(".", module.azure_aks.private_fqdn)))) 
#   dns_zone_resource_group = var.
#   add_to_dns              = true
# }

# # data "azurerm_virtual_network" "vpn-vnet" {
# #   name                = "GW-VNET"
# #   resource_group_name = "VPN-RG"
# # }

# # module "vnet_peering_vpn" {
# #   depends_on              = [module.hub_network] 
# #   source                  = "./modules/vnet_peering"
# #   tags                    = local.tags
# #   vnet_1_name             = "vnet-hub"
# #   vnet_1_id               = module.hub_network.vnet_id
# #   vnet_1_rg               = azurerm_resource_group.hub-rg.name
# #   vnet_2_name             = data.azurerm_virtual_network.vpn-vnet.name 
# #   vnet_2_id               = data.azurerm_virtual_network.vpn-vnet.id 
# #   vnet_2_rg               = "VPN-RG" 
# #   peering_name_1_to_2     = "HubToVPN"
# #   peering_name_2_to_1     = "VPNToHub"
# #   vnet1_network_gateway   = false 
# #   vnet1_use_remote_gateway= true 
# #   vnet2_network_gateway   = true 
# #   vnet2_use_remote_gateway= false 
# # }

# output "ssh_command" {
#  value = "ssh ${module.jumpbox.jumpbox_username}@${module.jumpbox.jumpbox_ip}"
# }

# output "jumpbox_password" {
#  description = "Jumpbox Admin Passowrd"
#  value       = module.jumpbox.jumpbox_password
# }
