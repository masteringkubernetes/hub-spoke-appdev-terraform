data "azurerm_client_config" "current" {}
data "azurerm_subscription" "primary" {}

data "azurerm_virtual_network" "hub-vnet" {
  name                   = var.hub-vnet-name
  resource_group_name    = var.hub-vnet-rg
}

resource "random_pet" "petname" {
  length        = 2
  separator     = "-"
}

resource "random_string" "random" {
  length        = 16
  special       = false
}

# Application 1 RG, VNET and Peering
resource "azurerm_resource_group" "app1-rg" {
  name     = "AKS1-APP-RG" 
  tags     = local.tags
  location = local.location
}

module "app1_spoke_network" {
  source              = "../modules/vnet"
  tags                = local.tags
  resource_group_name = azurerm_resource_group.app1-rg.name 
  location            = local.location
  vnet_name           = "vnet-spoke-app1"
  address_space       = ["192.168.0.0/16"]
  subnets = [
    {
      name : "clusternodes"
      address_prefixes : ["192.168.0.0/22"]
      private_link_endpoint_policies_enforced: false
      private_link_service_policies_enforced: false
    },
    {
      name : "clusteringressservices"
      address_prefixes : ["192.168.4.0/28"]
      private_link_endpoint_policies_enforced: false
      private_link_service_policies_enforced: false
    },
    {
      name : "applicationgateways"
      address_prefixes : ["192.168.4.16/28"]
      private_link_endpoint_policies_enforced: false
      private_link_service_policies_enforced: false
    },
    {
      name : "privatelinks"
      address_prefixes : ["192.168.4.32/28"]
      private_link_endpoint_policies_enforced: true
      private_link_service_policies_enforced: false
    },
    {
      name: "default",
      address_prefixes : ["192.168.4.48/28"]
      private_link_endpoint_policies_enforced: false
      private_link_service_policies_enforced: false   
    }
  ]
}

module "app1_vnet_peering" {
  source              = "../modules/vnet_peering"
  tags                = local.tags
  vnet_1_name         = var.hub-vnet-name 
  vnet_1_id           = data.azurerm_virtual_network.hub-vnet.id
  vnet_1_rg           = var.hub-vnet-rg 
  vnet_2_name         = "vnet-spoke-app1" 
  vnet_2_id           = module.app1_spoke_network.vnet_id
  vnet_2_rg           = azurerm_resource_group.app1-rg.name
  peering_name_1_to_2 = "HubToApp1Spoke"
  peering_name_2_to_1 = "App1SpokeToHub"

  depends_on = [module.app1_spoke_network]
}

resource "azurerm_private_dns_zone" "privatelink" {
  name                = "privatelink.azure.net"
  resource_group_name = azurerm_resource_group.app1-rg.name
}

module "jumpbox" {
  source                  = "../modules/jumpbox"
  tags                    = local.tags
  location                = local.location
  resource_group          = azurerm_resource_group.app1-rg.name 
  vnet_id                 = module.app1_spoke_network.vnet_id
  subnet_id               = module.app1_spoke_network.subnet_ids["default"]
  #dns_zone_name           = join(".", slice(split(".", module.azure_aks.private_fqdn), 1, length(split(".", module.azure_aks.private_fqdn)))) 
  dns_zone_name           = "privatelink.azure.net" 
  dns_zone_resource_group = azurerm_resource_group.app1-rg.name
  add_to_dns              = true

  depends_on = [azurerm_private_dns_zone.privatelink]
}


resource "azuread_application" "aks-app" {
  name                       = "${local.prefix}-aks-sp"
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = true
}

resource "azuread_service_principal" "aks-sp" {
  application_id               = azuread_application.aks-app.application_id
  app_role_assignment_required = false
}

resource "azuread_service_principal_password" "aks-sp-passwd" {
  service_principal_id = azuread_service_principal.aks-sp.id
  value                = random_string.random.result
  end_date             = "2021-01-01T01:02:03Z" 
}

# resource "tls_private_key" "ca" {
#   algorithm = "ECDSA"
#   ecdsa_curve = "P384"
# }

# resource "tls_self_signed_cert" "self-signed" {
#   key_algorithm   = "ECDSA"
#   private_key_pem = tls_private_key.ca.private_key_pem

#   subject {
#     common_name  = "test.com"
#     organization = "ACME Examples, Inc"
#   }

#   validity_period_hours = 8760

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#   ]
# }

# resource "azuread_service_principal_certificate" "aks-sp-cert" {
#   service_principal_id = azuread_service_principal.aks-sp.id
#   type                 = "AsymmetricX509Cert"
#   value                = tls_self_signed_cert.self-signed.cert_pem
#   end_date_relative    = "8759h"
# }

resource "azurerm_role_assignment" "contributor" {
  scope                       = azurerm_resource_group.app1-rg.id 
  role_definition_name        = "Contributor"
  principal_id                = azuread_service_principal.aks-sp.id
}

output "app-sp-id" {
  description = "Appid of SP"
  value       = azuread_service_principal.aks-sp.application_id
}

output "app-sp-password" {
  description = "Password of SP"
  value       = azuread_service_principal_password.aks-sp-passwd.value
}

# output "ssh_command" {
#  value = "ssh ${module.jumpbox.jumpbox_username}@${module.jumpbox.jumpbox_ip}"
# }

output "jumpbox_password" {
 description = "Jumpbox Admin Passowrd"
 value       = module.jumpbox.jumpbox_password
}
