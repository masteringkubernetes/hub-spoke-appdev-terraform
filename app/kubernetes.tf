# provider "kubernetes" {
#  load_config_file        = false
#  host                    = module.azure_aks.kube_config.0.host
#  #username                = module.azure_aks.kube_config.0.username
#  #password                = module.azure_aks.kube_config.0.password
#  client_certificate      = base64decode(module.azure_aks.kube_config.0.client_certificate)
#  client_key              = base64decode(module.azure_aks.kube_config.0.client_key)
#  cluster_ca_certificate  = base64decode(module.azure_aks.kube_config.0.cluster_ca_certificate)
# }

# provider "helm" {
#  kubernetes {
#    host                    = module.azure_aks.kube_config.0.host
#    #username                = module.azure_aks.kube_config.0.username
#    #password                = module.azure_aks.kube_config.0.password
#    client_certificate      = base64decode(module.azure_aks.kube_config.0.client_certificate)
#    client_key              = base64decode(module.azure_aks.kube_config.0.client_key)
#    cluster_ca_certificate  = base64decode(module.azure_aks.kube_config.0.cluster_ca_certificate)
#    load_config_file         = false
#  }
# }


# resource "kubernetes_namespace" "nginx" {
#  metadata {
#    annotations = {
#      name = "nginx"
#    }
#    name = "nginx"
#  }
# }

# resource "helm_release" "blue" {
#  count        = var.enable_blue_pool ? 1 : 0
#  name         = "ingress-blue"
#  repository   = "https://kubernetes.github.io/ingress-nginx"
#  chart        = "ingress-nginx"
#  namespace    = "nginx"
#  depends_on   = ["kubernetes_namespace.nginx"]

#  set_string {
#    name   = "controller.nodeSelector.nodepoolcolor"
#    value  = "blue"
#  }
 
#  set_string {
#    name   = "controller.nodeSelector.nodepoolmode"
#    value  = "user"
#  }

#  set {
#    name    = "controller.replicaCount"
#    value   = 2
#  }

#  set_string {
#    name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
#    value = "true"
#  }

#  set_string {
#    name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal-subnet"
#    value = "clusteringressservices"
#  }
  
#  set {
#    name = "controller.service.loadBalancerIP"
#    value = module.appgateway.blue_backend_ip_addresses[0]
#  }

#  set {
#    name = "controller.ingressClass"
#    value = "blue"
#  }
# }

# resource "helm_release" "green" {
#  count        = var.enable_green_pool ? 1 : 0
#  name         = "ingress-green"
#  repository   = "https://kubernetes.github.io/ingress-nginx"
#  chart        = "ingress-nginx"
#  namespace    = "nginx"
#  depends_on   = ["kubernetes_namespace.nginx"]

#  set_string {
#    name   = "controller.nodeSelector.nodepoolcolor"
#    value  = "green"
#  }
 
#  set_string {
#    name   = "controller.nodeSelector.nodepoolmode"
#    value  = "user"
#  }

#  set {
#    name    = "controller.replicaCount"
#    value   = 2
#  }

#  set_string {
#    name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
#    value = "true"
#  }

#  set_string {
#    name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal-subnet"
#    value = "clusteringressservices"
#  }
  
#  set {
#    name = "controller.service.loadBalancerIP"
#    value = module.appgateway.green_backend_ip_addresses[0]
#  }

#  set {
#    name = "controller.ingressClass"
#    value = "green"
#  }
# }
