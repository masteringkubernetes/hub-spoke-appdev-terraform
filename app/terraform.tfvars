app_rg = "AKS1-APP-RG"
location = "usgovvirginia"
aks_cp_version = "1.19.7"
aks_blue_version = "1.19.7"
aks_green_version = "1.19.7"
az_sp_app_id = "XXXXXXXXXXXX"
az_sp_password = "XXXXXXXXXXXXXXX"
app_vnet_name = "vnet-spoke-app1"
firewall_private_ip = "10.200.0.4"

active_backend_pool = "blue"
enable_blue_pool    = true
enable_green_pool   = false
drain_green_pool    = false
drain_blue_pool     = false

