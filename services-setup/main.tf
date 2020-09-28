variable "full_path_to_certs" {
  default = "/Users/mgutnik/Projects/io.cerebros.infra/kubernetes-setup/certs"
}
provider "kubernetes" {
  config_path = "${var.full_path_to_certs}/config"
}
module "tiller" {
  source  = "terraform-module/tiller/kubernetes"
  version = "2.0.0"
  namespace       = "kube-system"
  service_namespaces = ["helm"]
}
provider "helm" {
  kubernetes {
      config_path = "${var.full_path_to_certs}/config"
  }
}
resource "helm_release" "ingress" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart = "nginx-ingress"
  name = "ingress"
  namespace = "nginx-ingress"
  create_namespace = "true"
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

resource "kubernetes_cluster_role" "kubernetes_dashboard_anonymous" {
    metadata {
        name = "kubernetes-dashboard-anonymous"
    }

    rule {
        api_groups     = [""]
        resources      = ["services/proxy"]
        resource_names = ["https:kubernetes-dashboard:"]
        verbs          = ["get", "list", "watch", "create", "update", "patch", "delete"]
    }
    rule {
      non_resource_urls  = ["/ui", "/ui/*", "/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/*"]
      verbs              = ["get", "list", "watch", "create", "update", "patch", "delete"]
    }
}

resource "kubernetes_cluster_role_binding" "kubernetes_dashboard_anonymous" {
  depends_on = [kubernetes_cluster_role.kubernetes_dashboard_anonymous]
  metadata {
    name = "kubernetes-dashboard-anonymous"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "kubernetes-dashboard-anonymous"
  }
  subject {
    kind = "User"
    name = "system:anonymous"
    namespace = "kubernetes-dashboard"
  }
}
