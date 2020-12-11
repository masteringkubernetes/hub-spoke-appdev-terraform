# output principal_id {
#   description = "Generated Principal ID"
#   value       = azurerm_kubernetes_cluster.modaks.identity[0].principal_id
# }

output control_plane_aks_version {
  description = "Generated Principal ID"
  value       = azurerm_kubernetes_cluster.modaks.kubernetes_version
}

output cluster_resource_id {
  value       = azurerm_kubernetes_cluster.modaks.id
}

output kube_config_raw {
  value       = azurerm_kubernetes_cluster.modaks.kube_admin_config_raw
}

output kube_config {
  value       = azurerm_kubernetes_cluster.modaks.kube_config
}

output private_fqdn {
  value       = azurerm_kubernetes_cluster.modaks.private_fqdn
}

output node_resource_group {
  value       = azurerm_kubernetes_cluster.modaks.node_resource_group
}
