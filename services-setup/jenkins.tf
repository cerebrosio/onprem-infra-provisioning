resource "helm_release" "jenkins" {
  name  = "jenkins"
  chart = "jenkins"
  namespace = "jenkins"
  repository  = "https://charts.helm.sh/stable"
  create_namespace = "true"
  values = [
    "${file("helm-values-jenkins.yaml")}"
  ]
  timeout = "600"
} 
