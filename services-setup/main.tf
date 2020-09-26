variable "full_path_to_certs" {
  default = "/Users/mgutnik/Projects/io.cerebros.infra/kubernetes-setup/certs"
}

provider "kubernetes" {
  #  config_context_cluster   = "minikube"
  #host = "http://192.168.50.10:6443"
  #client_certificate     = file("${var.full_path_to_certs}/front-proxy-client.crt") #client-cert.pem
  #client_key             = file("${var.full_path_to_certs}/front-proxy-client.key")  #client-key.pem
  #cluster_ca_certificate = file("${var.full_path_to_certs}/front-proxy-ca.crt") #cluster-ca-cert.pem
  config_path = file("${var.full_path_to_certs}/config")
  load_config_file = true
}
module "tiller" {
  source  = "terraform-module/tiller/kubernetes"
  version = "2.0.0"
  namespace       = "kube-system"
  service_namespaces = ["helm"]
}
provider "helm" {
  kubernetes {
#      config_context_cluster   = "minikube"
      #host = "http://192.168.50.10:6443"
      #client_certificate     = file("${var.full_path_to_certs}/front-proxy-client.crt") #client-cert.pem
      #client_key             = file("${var.full_path_to_certs}/front-proxy-client.key")  #client-key.pem
      #cluster_ca_certificate = file("${var.full_path_to_certs}/front-proxy-ca.crt") #cluster-ca-cert.pem
      config_path = file("${var.full_path_to_certs}/config")
      load_config_file = true 
  }
}
resource "helm_release" "jenkins" {
  name  = "jenkins"
  chart = "jenkins"
  namespace = "jenkins"
  repository  = "https://kubernetes-charts.storage.googleapis.com/"
  create_namespace = "true"
  values = [
    "${file("helm-values-jenkins.yaml")}"
  ]
#  set {
#    name  = "master.adminUser"
#    value = "admin"
#    type = "string"
#  }
#  set {
#    name  = "master.adminPassword"
#    value = "qwerty"
#    type = "string"
#  }
}
module "kubernetes_dashboard" {
  source = "cookielab/dashboard/kubernetes"
  version = "0.9.0"

  kubernetes_namespace_create = true
  kubernetes_dashboard_csrf = "qwerty"
}
resource "kubernetes_service_account" "admin_user" {
  metadata {
    name = "admin-user"
    namespace = "kubernetes-dashboard"
  }
}
resource "kubernetes_cluster_role_binding" "admin_user" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    namespace = "kubernetes-dashboard"
    kind      = "ServiceAccount"
    name      = "admin-user"
  }
}
