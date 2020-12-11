resource "azurerm_public_ip" "appgwpip" {
  name                = "app-gw-pip"
  resource_group_name = var.resource_group
  location            = var.location 
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_blue      = "${var.name}-blue"
  backend_address_pool_green     = "${var.name}-green"
  backend_address_pool_name      = var.active_backend == "blue" ? local.backend_address_pool_blue : local.backend_address_pool_green
  frontend_port_name             = "${var.name}-feport"
  frontend_ip_configuration_name = "${var.name}-feip"
  http_setting_name              = "${var.name}-be-htst"
  listener_name                  = "${var.name}-httplstn"
  request_routing_rule_name      = "${var.name}-rqrt"
  redirect_configuration_name    = "${var.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = var.name 
  resource_group_name = var.resource_group
  location            = var.location 
  tags                = var.tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity    = 1
    max_capacity    = 3
  }

  gateway_ip_configuration {
    name      = "${var.name}-gateway-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgwpip.id
  }

  backend_address_pool {
    name                = local.backend_address_pool_blue
    ip_addresses        = var.blue_backend_ip_addresses
  }
  
  backend_address_pool {
    name                = local.backend_address_pool_green
    ip_addresses        = var.green_backend_ip_addresses
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  identity {
    type                        = "UserAssigned"
    identity_ids                = var.identity_ids
  }

}