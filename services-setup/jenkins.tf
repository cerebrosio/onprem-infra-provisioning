resource "helm_release" "jenkins" {
  name  = "jenkins"
  chart = "jenkins"
  namespace = "jenkins"
  repository  = "https://kubernetes-charts.storage.googleapis.com/"
  create_namespace = "true"
  values = [
    "${file("helm-values-jenkins.yaml")}"
  ]
} 