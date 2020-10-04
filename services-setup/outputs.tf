data "kubernetes_secret" "admin_user" {
  metadata {
    namespace = "kubernetes-dashboard"
    name = "${kubernetes_service_account.admin_user.default_secret_name}"
  }
}

output "dashboard_token" {
  value = "${lookup(data.kubernetes_secret.admin_user.data, "token")}"
}

resource "local_file" "dashboard_token" {
    content  = lookup(data.kubernetes_secret.admin_user.data, "token")
    filename = "dashboard_token.txt"
}