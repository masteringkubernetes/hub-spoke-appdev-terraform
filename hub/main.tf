data "azurerm_client_config" "current" {}
data "azurerm_subscription" "primary" {}

resource "random_pet" "petname" {
  length        = 2
  separator     = "-"
}

resource "random_string" "random" {
  length        = 16
  special       = false
}

resource "azurerm_resource_group" "hub-rg" {
  name     = "HUB-RG"
  tags     = local.tags
  location = local.location
}

module "hub_network" {
  source              = "../modules/vnet"
  tags                = local.tags
  resource_group_name = azurerm_resource_group.hub-rg.name 
  location            = local.location
  vnet_name           = "vnet-hub" 
  address_space       = ["10.200.0.0/24"]
  subnets = [
    {
      name : "AzureFirewallSubnet"
      address_prefixes : ["10.200.0.0/26"]
      private_link_endpoint_policies_enforced: false
      private_link_service_policies_enforced: false
    },
    {
      name : "GatewaySubnet"
      address_prefixes : ["10.200.0.64/27"]
      private_link_endpoint_policies_enforced: false
      private_link_service_policies_enforced: false
    },
    {
      name : "AzureBastionSubnet"
      address_prefixes : ["10.200.0.96/27"]
      private_link_endpoint_policies_enforced: false
      private_link_service_policies_enforced: false
    },
    {
      name : "default"
      address_prefixes : ["10.200.0.128/27"]
      private_link_endpoint_policies_enforced: false
      private_link_service_policies_enforced: false
    },
    {
      name : "other"
      address_prefixes : ["10.200.0.160/27"]
      private_link_endpoint_policies_enforced: false
      private_link_service_policies_enforced: false
    }
  ]
}

module "firewall" {
  source         = "../modules/firewall"
  tags           = local.tags
  resource_group = azurerm_resource_group.hub-rg.name 
  location       = local.location
  pip_name       = "pip-fw-default"
  fw_name        = "fw-hub"
  subnet_id      = module.hub_network.subnet_ids["AzureFirewallSubnet"]
}

resource "azurerm_public_ip" "bastion-pip" {
  name                = "bastionpip"
  location            = local.location
  resource_group_name = azurerm_resource_group.hub-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion-host" {
  name                = "bastion"
  location            = local.location
  resource_group_name = azurerm_resource_group.hub-rg.name

  ip_configuration {
    name                 = "ip-config"
    subnet_id            = module.hub_network.subnet_ids["AzureBastionSubnet"] 
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
}
