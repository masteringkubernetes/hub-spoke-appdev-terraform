locals {
  bluesystem_name     = "${var.blue_pool.name}system"
  blueuser_name       = "${var.blue_pool.name}user"
  greensystem_name    = "${var.green_pool.name}system"
  greenuser_name      = "${var.green_pool.name}user"
}

resource "azurerm_kubernetes_cluster" "modaks" {
  lifecycle {
    #prevent_destroy = true
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }

  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  dns_prefix                      = var.name
  kubernetes_version              = var.control_plane_kubernetes_version
  node_resource_group             = "${var.resource_group_name}-worker"
  private_cluster_enabled         = var.private_cluster
  sku_tier                        = var.sla_sku
  api_server_authorized_ip_ranges = var.api_auth_ips

  default_node_pool {
    name                          = substr(var.default_node_pool.name, 0, 12)
    orchestrator_version          = var.control_plane_kubernetes_version
    node_count                    = 1
    vm_size                       = var.default_node_pool.vm_size
    type                          = "VirtualMachineScaleSets"
    availability_zones            = null
    max_pods                      = 30  # Cannot be less than 30 for single node
    os_disk_size_gb               = 128
    vnet_subnet_id                = var.vnet_subnet_id
    node_labels                   = null 
    node_taints                   = null
    enable_auto_scaling           = false
    min_count                     = null 
    max_count                     = null 
    enable_node_public_ip         = false
  }
  
  service_principal {
    client_id                     = var.client_id 
    client_secret                 = var.client_secret
  }
  role_based_access_control {
    enabled = true
  }

  network_profile {
    docker_bridge_cidr            = "172.18.0.1/16"
    dns_service_ip                = "172.16.0.10"
    network_plugin                = "kubenet"
    outbound_type                 = "userDefinedRouting"
    service_cidr                  = "172.16.0.0/16"
    pod_cidr                      = "172.15.0.0/16"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "system-green-pool" {
  lifecycle {
    ignore_changes = [
      node_count, node_labels, node_taints
    ]
  }
  depends_on = [azurerm_kubernetes_cluster_node_pool.system-blue-pool, azurerm_kubernetes_cluster_node_pool.user-blue-pool]

  count                           = var.enable_green_pool ? 1 : 0
  kubernetes_cluster_id           = azurerm_kubernetes_cluster.modaks.id
  mode                            = "System"
  name                            = var.blue_pool.node_os == "Windows" ? substr(local.greensystem_name, 0, 6) : substr(local.greensystem_name, 0, 12)
  orchestrator_version            = var.green_pool.pool_kubernetes_version
  node_count                      = var.green_pool.system_min_count 
  vm_size                         = var.green_pool.system_vm_size
  availability_zones              = ["1", "2", "3"]
  tags                            = var.green_pool.azure_tags
  max_pods                        = 30 
  os_disk_size_gb                 = var.green_pool.system_disk_size 
  os_type                         = var.green_pool.node_os
  vnet_subnet_id                  = var.vnet_subnet_id
  node_labels                     = {
    nodepoolcolor="green"
    nodepoolmode="system"
  }
  node_taints                     = ["CriticalAddonsOnly=true:NoSchedule"]
  enable_auto_scaling             = true 
  min_count                       = var.green_pool.system_min_count
  max_count                       = var.green_pool.system_max_count
  enable_node_public_ip           = false
}

resource "azurerm_kubernetes_cluster_node_pool" "user-green-pool" {
  lifecycle {
    ignore_changes = [
      node_count, node_labels, node_taints
    ]
  }
  
  depends_on = [azurerm_kubernetes_cluster_node_pool.system-blue-pool, azurerm_kubernetes_cluster_node_pool.user-blue-pool, azurerm_kubernetes_cluster_node_pool.system-green-pool]

  count                           = var.enable_green_pool ? 1 : 0
  kubernetes_cluster_id           = azurerm_kubernetes_cluster.modaks.id
  mode                            = "User"
  name                            = var.blue_pool.node_os == "Windows" ? substr(local.greenuser_name, 0, 6) : substr(local.greenuser_name, 0, 12)
  orchestrator_version            = var.green_pool.pool_kubernetes_version
  node_count                      = var.green_pool.user_min_count 
  vm_size                         = var.green_pool.user_vm_size
  availability_zones              = ["1", "2", "3"]
  tags                            = var.green_pool.azure_tags
  max_pods                        = 30
  os_disk_size_gb                 = var.green_pool.user_disk_size
  os_type                         = var.green_pool.node_os
  vnet_subnet_id                  = var.vnet_subnet_id
  node_labels                     = {
    nodepoolcolor="green"
    nodepoolmode="user"
  }
  node_taints                     = null 
  enable_auto_scaling             = true 
  min_count                       = var.green_pool.user_min_count
  max_count                       = var.green_pool.user_max_count
  enable_node_public_ip           = false
}

resource "azurerm_kubernetes_cluster_node_pool" "system-blue-pool" {
  lifecycle {
    ignore_changes = [
      node_count, node_labels, node_taints
    ]
  }
  count                           = var.enable_blue_pool ? 1 : 0
  kubernetes_cluster_id           = azurerm_kubernetes_cluster.modaks.id
  mode                            = "System"
  name                            = var.blue_pool.node_os == "Windows" ? substr(local.bluesystem_name, 0, 6) : substr(local.bluesystem_name, 0, 12)
  orchestrator_version            = var.blue_pool.pool_kubernetes_version
  node_count                      = var.blue_pool.system_min_count 
  vm_size                         = var.blue_pool.system_vm_size
  availability_zones              = ["1", "2", "3"]
  tags                            = var.blue_pool.azure_tags
  max_pods                        = 30
  os_disk_size_gb                 = var.blue_pool.system_disk_size
  os_type                         = var.blue_pool.node_os
  vnet_subnet_id                  = var.vnet_subnet_id
  node_labels                     = {
    nodepoolcolor="blue"
    nodepoolmode="system"
  }
  node_taints                     = ["CriticalAddonsOnly=true:NoSchedule"]
  enable_auto_scaling             = true 
  min_count                       = var.blue_pool.system_min_count
  max_count                       = var.blue_pool.system_max_count
  enable_node_public_ip           = false
}

resource "azurerm_kubernetes_cluster_node_pool" "user-blue-pool" {
  lifecycle {
    ignore_changes = [
      node_count, node_labels, node_taints
    ]
  }

  depends_on                      = [azurerm_kubernetes_cluster_node_pool.system-blue-pool]

  count                           = var.enable_blue_pool ? 1 : 0
  kubernetes_cluster_id           = azurerm_kubernetes_cluster.modaks.id
  mode                            = "User"
  name                            = var.blue_pool.node_os == "Windows" ? substr(local.blueuser_name, 0, 6) : substr(local.blueuser_name, 0, 12)
  orchestrator_version            = var.blue_pool.pool_kubernetes_version
  node_count                      = var.blue_pool.user_min_count 
  vm_size                         = var.blue_pool.user_vm_size
  availability_zones              = ["1", "2", "3"]
  tags                            = var.blue_pool.azure_tags
  max_pods                        = 30
  os_disk_size_gb                 = var.blue_pool.user_disk_size
  os_type                         = var.blue_pool.node_os
  vnet_subnet_id                  = var.vnet_subnet_id
  node_labels                     = {
    nodepoolcolor="blue"
    nodepoolmode="user"
  }
  node_taints                     = null
  enable_auto_scaling             = true 
  min_count                       = var.blue_pool.user_min_count
  max_count                       = var.blue_pool.user_max_count
  enable_node_public_ip           = false
} 

resource "null_resource" "drain-green" {
  triggers = {
    private_cluster   = var.private_cluster
    drain_green       = var.drain_green_pool
    raw_config        = azurerm_kubernetes_cluster.modaks.kube_config_raw
  }
  #count        = var.drain_green_pool && !var.private_cluster ? 1 : 0
  count        = var.drain_green_pool ? 1 : 0

  provisioner "local-exec" {
    when    = destroy 
    command = <<EOF
      if [ ${self.triggers.private_cluster} ]; then
         echo "Cannot uncordon and taint nodes in a private cluster using these scripts. Skipping..."
         exit 0
      fi
      echo "Will untaint Green nodepool."
      for node in $(kubectl get nodes -l nodepoolcolor=green -o name --kubeconfig <(echo $KUBECONFIG | base64 --decode)); do
        kubectl uncordon "$node" --kubeconfig <(echo $KUBECONFIG | base64 --decode)
        kubectl taint nodes "$node" GettingUpgraded=true:NoSchedule- --kubeconfig <(echo $KUBECONFIG | base64 --decode) 
      done
    EOF
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = "${base64encode(self.triggers.raw_config)}"
    }
  }

  provisioner "local-exec" {
    command = <<EOF
      if [ "${var.private_cluster}" == "true" ]; then
         echo "Cannot drain a private cluster using these scripts"
         exit 0
      fi

      if [ "${var.enable_green_pool}" != "true" ]; then
        echo "Green pool is not enabled.  Cannot drain Blue pool."
        exit 0
      fi

      if [ "${var.enable_blue_pool}" != "true" ]; then
        echo "Blue pool not enabled.  Cannot drain green pool because there is nowhere for the pods to go."
        exit 1
      fi      

      if [ "${var.drain_blue_pool}" == "true" ]; then
        echo "Blue pool is already being drained.  Cannot drain Green."
        exit 1
      fi

      # Check if green can be scheduled
      NUMBER_NODES_AVAILABLE=$(kubectl get nodes -l nodepoolcolor=blue --no-headers --kubeconfig <(echo $KUBECONFIG | base64 --decode) | grep -v SchedulingDisabled)
      echo "Nodes available in Blue Pool=$NUMBER_NODES_AVAILABLE"
      if [ "$NUMBER_NODES_AVAILABLE" -lt 1 ]; then
        echo "No Blue Nodes available to schedule on.  Check the taints for NoSchedule"
        exit 1
      fi

      for node in $(kubectl get nodes -l nodepoolcolor=green -o name --kubeconfig <(echo $KUBECONFIG | base64 --decode)); do
        kubectl taint nodes "$node" GettingUpgraded=true:NoSchedule --overwrite=true --kubeconfig <(echo $KUBECONFIG | base64 --decode) 
      done

      for node in $(kubectl get nodes -l nodepoolcolor=green -o name --kubeconfig <(echo $KUBECONFIG | base64 --decode)); do
        kubectl drain "$node" --ignore-daemonsets --delete-local-data --kubeconfig <(echo $KUBECONFIG | base64 --decode) 
      done
    EOF
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = "${base64encode(azurerm_kubernetes_cluster.modaks.kube_config_raw)}"
    }
  }
  # Marking these nodes as NoExecute requires the system pool to be available
  depends_on = [azurerm_kubernetes_cluster_node_pool.system-blue-pool, azurerm_kubernetes_cluster_node_pool.user-blue-pool, azurerm_kubernetes_cluster_node_pool.system-green-pool, azurerm_kubernetes_cluster_node_pool.user-green-pool]
}


resource "null_resource" "drain-blue" {
  triggers = {
    private_cluster = var.private_cluster
    drain_blue      = var.drain_blue_pool
    raw_config      = azurerm_kubernetes_cluster.modaks.kube_config_raw
  }
  
  #count     = var.drain_blue_pool && !var.private_cluster ? 1 : 0
  count     = var.drain_blue_pool ? 1 : 0

  provisioner "local-exec" {
    when    = destroy 
    command = <<EOF
      if [ ${self.triggers.private_cluster} ]; then
         echo "Cannot uncordon and taint nodes in a private cluster using these scripts. Skipping..."
         exit 0
      fi
      echo "Will untaint Blue nodepool."
      for node in $(kubectl get nodes -l nodepoolcolor=blue -o name --kubeconfig <(echo $KUBECONFIG | base64 --decode)); do
        kubectl uncordon "$node" --kubeconfig <(echo $KUBECONFIG | base64 --decode)
        kubectl taint nodes "$node" GettingUpgraded=true:NoSchedule- --kubeconfig <(echo $KUBECONFIG | base64 --decode) 
      done
    EOF
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = "${base64encode(self.triggers.raw_config)}"
    }
  }

  provisioner "local-exec" {
    command = <<EOF
      if [ "${var.private_cluster}" == "true" ]; then
         echo "Cannot drain a private cluster using these scripts"
         exit 0
      fi

      if [ "${var.enable_blue_pool}" != "true" ]; then
        echo "Blue pool is not enabled.  Cannot drain Green pool."
        exit 0
      fi

      if [ "${var.enable_green_pool}" != "true" ]; then
        echo "Green pool not enabled.  Cannot drain blue pool because there is nowhere for the pods to go."
        exit 1
      fi      
      
      if [ "${var.drain_green_pool}" == "true" ]; then
        echo "Green pool is already being drained.  Cannot drain Blue."
        exit 1
      fi

      # Check if green can be scheduled
      NUMBER_NODES_AVAILABLE=$(kubectl get nodes -l nodepoolcolor=green --no-headers --kubeconfig <(echo $KUBECONFIG | base64 --decode) | grep -v SchedulingDisabled)
      echo "Nodes available in Green Pool=$NUMBER_NODES_AVAILABLE"
      if [ "$NUMBER_NODES_AVAILABLE" -lt 1 ]; then
        echo "No Green Nodes available to schedule on.  Check the taints for NoSchedule"
        exit 1
      fi

      for node in $(kubectl get nodes -l nodepoolcolor=blue -o name --kubeconfig <(echo $KUBECONFIG | base64 --decode)); do
        kubectl taint nodes "$node" GettingUpgraded=true:NoSchedule --overwrite=true --kubeconfig <(echo $KUBECONFIG | base64 --decode) 
      done

      for node in $(kubectl get nodes -l nodepoolcolor=blue -o name --kubeconfig <(echo $KUBECONFIG | base64 --decode)); do
        kubectl drain "$node" --ignore-daemonsets --delete-local-data --kubeconfig <(echo $KUBECONFIG | base64 --decode) 
      done
    EOF
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = "${base64encode(azurerm_kubernetes_cluster.modaks.kube_config_raw)}"
    }
  }
  # Marking these nodes as NoExecute requires the system pool to be available
  depends_on = [azurerm_kubernetes_cluster_node_pool.system-blue-pool, azurerm_kubernetes_cluster_node_pool.user-blue-pool, azurerm_kubernetes_cluster_node_pool.system-green-pool, azurerm_kubernetes_cluster_node_pool.user-green-pool]
}


resource "null_resource" "kubectl" {
  triggers = {
    default_node_version = azurerm_kubernetes_cluster.modaks.default_node_pool.0.orchestrator_version
  }

  provisioner "local-exec" {
    command = <<EOF
      for node in $(kubectl get nodes -l agentpool=default1 -o name --kubeconfig <(echo $KUBECONFIG | base64 --decode)); do
        kubectl taint nodes "$node" default=true:NoExecute --overwrite=true --kubeconfig <(echo $KUBECONFIG | base64 --decode) 
      done
    EOF
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = "${base64encode(azurerm_kubernetes_cluster.modaks.kube_config_raw)}"
    }
  }
  # Marking these nodes as NoExecute requires the system pool to be available
  depends_on = [azurerm_kubernetes_cluster_node_pool.system-green-pool, azurerm_kubernetes_cluster_node_pool.system-blue-pool]
}

