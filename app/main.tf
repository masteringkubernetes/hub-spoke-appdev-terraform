data "azurerm_client_config" "current" {}
data "azurerm_subscription" "primary" {}

data "azurerm_virtual_network" "app-vnet" {
  name                   = var.app_vnet_name
  resource_group_name    = var.app_rg
}

data "azurerm_subnet" "app-vnet-clusteringressservices" {
  name                 = "clusteringressservices"
  virtual_network_name = var.app_vnet_name
  resource_group_name  = var.app_rg
}

data "azurerm_subnet" "app-vnet-clusternodes" {
  name                 = "clusternodes"
  virtual_network_name = var.app_vnet_name
  resource_group_name  = var.app_rg
}

data "azurerm_subnet" "app-vnet-privatelinks" {
  name                 = "privatelinks"
  virtual_network_name = var.app_vnet_name
  resource_group_name  = var.app_rg
}

data "azurerm_subnet" "app-vnet-applicationgateways" {
  name                 = "applicationgateways"
  virtual_network_name = var.app_vnet_name
  resource_group_name  = var.app_rg
}

resource "random_pet" "petname" {
  length        = 2
  separator     = "-"
}

resource "random_string" "random" {
  length        = 16
  special       = false
}


module "routetable" {
  source              = "../modules/route_table"
  tags                = local.tags
  resource_group      = var.app_rg
  location            = local.location
  rt_name             = "kubenetfw_fw_rt"
  r_name              = "kubenetfw_fw_r"
  firewall_private_ip = var.firewall_private_ip
  subnet_id           = data.azurerm_subnet.app-vnet-clusternodes.id
}


module "azure_aks" {
  depends_on                        = [module.routetable, azurerm_container_registry.acr]

  source                            = "../modules/azure_aks"
  name                              = "bg-aks"
  container_registry_id             = azurerm_container_registry.acr.id 
  control_plane_kubernetes_version  = var.aks_cp_version 
  resource_group_name               = var.app_rg
  location                          = local.location
  vnet_subnet_id                    = data.azurerm_subnet.app-vnet-clusternodes.id
  api_auth_ips                      = null
  private_cluster                   = true
  sla_sku                           = "Free"
  client_id                         = var.az_sp_app_id 
  client_secret                     = var.az_sp_password 
  
  default_node_pool = {
    name                           = "default"
    vm_size                        = "Standard_D2_v2"
  }

  addons = {
    oms_agent                       = true
    azure_policy                    = true
    kubernetes_dashboard            = false
  }

  # enable_blue_pool=true will ensure 2 node pools exist (bluesystem, blueuser)
  # enable_blue_pool=false will delete bluesystem and blueuser node pools
  # drain_blue_pool=true will taint and drain the blue node pool (bluesystem and blueuser).  It does NOT delete it.
  enable_blue_pool                  = var.enable_blue_pool 
  drain_blue_pool                   = var.drain_blue_pool 
  blue_pool = {
    name                            = "blue"
    system_min_count                = 1 
    system_max_count                = 3
    user_min_count                  = 1 
    user_max_count                  = 6
    system_vm_size                  = "Standard_D2_v2"
    user_vm_size                    = "Standard_DS2_v2"
    system_disk_size                = 128
    user_disk_size                  = 512 
    zones                           = ["1", "2", "3"]
    node_os                         = "Linux"
    azure_tags                      = null
    pool_kubernetes_version         = var.aks_blue_version 
  }

  # enable_green_pool=true will ensure 2 node pools exist (greensystem, greenuser)
  # enable_green_pool=false will delete greensystem and greenuser node pools
  # drain_green_pool=true will taint and drain the green node pool (greensystem and greenuser).  It does NOT delete it.
  enable_green_pool                 = var.enable_green_pool 
  drain_green_pool                  = var.drain_green_pool 
  green_pool = {
    name                            = "green"
    system_min_count                = 1 
    system_max_count                = 3
    user_min_count                  = 1 
    user_max_count                  = 3
    system_vm_size                  = "Standard_D2_v2"
    user_vm_size                    = "Standard_DS2_v2"
    system_disk_size                = 128 
    user_disk_size                  = 512 
    zones                           = ["1", "2", "3"]
    node_os                         = "Linux"
    azure_tags                      = null
    pool_kubernetes_version         = var.aks_green_version 
  }
}


# App gateway is a hub component but is listed here because it more closely aligns with the workload
# in this particular configuration.  Since we are using one app gateway per application
module "appgateway" {
  source                    = "../modules/app_gateway"
  name                      = "appgateway"
  tags                      = local.tags
  location                  = local.location
  resource_group            = var.app_rg
  subnet_id                 = data.azurerm_subnet.app-vnet-applicationgateways.id
  blue_backend_ip_addresses = [cidrhost(data.azurerm_subnet.app-vnet-clusteringressservices.address_prefix, 4)]
  green_backend_ip_addresses = [cidrhost(data.azurerm_subnet.app-vnet-clusteringressservices.address_prefix, 5)]
  active_backend            = var.active_backend_pool
  identity_ids              = [azurerm_user_assigned_identity.appw-to-keyvault.id]
}


resource "azurerm_key_vault" "vault" {
  name                  = replace(local.vault_name, "-", "")
  location              = local.location
  resource_group_name   = var.app_rg
  sku_name              = "standard"
  tenant_id             = data.azurerm_client_config.current.tenant_id
  tags                  = local.tags
  
  
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "get","list","create","delete","encrypt","decrypt","unwrapKey","wrapKey"
    ]

    secret_permissions = [
      "get","list","set","delete"
    ]
  } 
  
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.aksic-to-keyvault.principal_id
    
    key_permissions = [
      "get"
    ]

    secret_permissions = [
      "get"
    ]
  } 
  
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.appw-to-keyvault.principal_id

    key_permissions = [
      "get"
    ]

    secret_permissions = [
      "get"
    ]
  } 
}


resource "azurerm_container_registry" "acr" {
  name                     = replace(local.registry_name, "-", "")
  resource_group_name      = var.app_rg
  location                 = local.location
  sku                      = "Premium"
  admin_enabled            = false
}

resource "azurerm_private_endpoint" "akv-endpoint" {
  name                = "nodepool-to-akv" 
  location            = local.location
  resource_group_name = var.app_rg
  subnet_id           = data.azurerm_subnet.app-vnet-privatelinks.id

  private_service_connection {
    name                            = "nodepoolsubnet-to-akv" 
    private_connection_resource_id  = azurerm_key_vault.vault.id
    is_manual_connection            = false
    subresource_names               = ["vault"]
  }
}

resource "azurerm_private_endpoint" "acr-endpoint" {
  name                = "nodepool-to-acr" 
  location            = local.location
  resource_group_name = var.app_rg
  subnet_id           = data.azurerm_subnet.app-vnet-privatelinks.id

  private_service_connection {
    name                            = "nodepoolsubnet-to-acr" 
    private_connection_resource_id  = azurerm_container_registry.acr.id
    is_manual_connection            = false
    subresource_names               = ["registry"]
  }
}

# resource "azurerm_private_dns_zone" "dns-zone" {
#   name                = "privatelink.azure.net"
#   resource_group_name = var.app_rg
#   tags                = local.tags
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "hublink" {
#   name                  = "hubnetdnsconfig"
#   resource_group_name   = var.app_rg
#   private_dns_zone_name = azurerm_private_dns_zone.dns-zone.name
#   virtual_network_id    = data.azurerm_virtual_network.app-vnet.id
#   tags                  = local.tags
# }

resource "azurerm_private_dns_a_record" "acr-dnsrecord" {
  name                = azurerm_container_registry.acr.name
  zone_name           = "privatelink.azure.net"
  resource_group_name = var.app_rg
  ttl                 = 300
  records             = [azurerm_private_endpoint.acr-endpoint.private_service_connection[0].private_ip_address]

  depends_on          = [azurerm_private_endpoint.acr-endpoint]
}

resource "azurerm_private_dns_a_record" "akv-dnsrecord" {
  name                = azurerm_key_vault.vault.name
  zone_name           = "privatelink.azure.net"
  resource_group_name = var.app_rg
  ttl                 = 300
  records             = [azurerm_private_endpoint.akv-endpoint.private_service_connection[0].private_ip_address]
  
  depends_on          = [azurerm_private_endpoint.akv-endpoint]
}

resource "azurerm_user_assigned_identity" "appw-to-keyvault" {
  resource_group_name = var.app_rg
  location            = local.location
  tags                = local.tags
  name                = "appw-to-keyvault"
}

resource "azurerm_user_assigned_identity" "aksic-to-keyvault" {
  resource_group_name = var.app_rg
  location            = local.location
  tags                = local.tags
  name                = "aksic-to-keyvault"
}

