# output backend_address_pool {
#   value = azurerm_application_gateway.network.backend_address_pool[0].ip_addresses
# }

output backend_address_pool {
  value = azurerm_application_gateway.network.backend_address_pool.*.ip_addresses
}


output frontend_ip_configuration {
  value = azurerm_public_ip.appgwpip.ip_address
}
