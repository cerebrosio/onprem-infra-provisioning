variable "full_path_to_certs" {
  default = "/Users/mgutnik/Projects/io.cerebros.infra/kubernetes-setup/certs"
}
provider "kubernetes" {
  config_path = "${var.full_path_to_certs}/config"
}

resource "kubernetes_persistent_volume" "nfs-volume-data" {
  metadata {
    name = "nfs-volume-data"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      nfs {
        path   = "/opt/k8s-data"
        server = "192.168.50.50"
      }
    }
  }
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

module "kubernetes_dashboard" {
  source = "cookielab/dashboard/kubernetes"
  version = "0.11.0"
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
  depends_on = [kubernetes_service_account.admin_user]
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
      non_resource_urls  = ["/ui", "/ui/*", "/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/*"]
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

resource "helm_release" "nginx_ingress" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart = "nginx-ingress"
  name = "nginx-ingress"
  namespace = "nginx-ingress"
  create_namespace = "true"
  values = [
    "${file("helm-values-ingress.yaml")}"
  ]
}
