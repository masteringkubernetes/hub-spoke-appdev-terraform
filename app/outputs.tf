output "keyvault_name" {
 description = "Keyvault name"
 value       = azurerm_key_vault.vault.name
}

output appgateway_frontend_ip_configuration {
  value = module.appgateway.frontend_ip_configuration
}
