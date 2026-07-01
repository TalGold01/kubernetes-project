resource "helm_release" "luxe_app" {
  name             = "luxe-app"
  chart            = "${path.module}/../helm/luxe-app"
  namespace        = "luxe-app-${var.environment}"
  create_namespace = true
  timeout          = 600

  # Dynamically select values-dev.yaml or values-prod.yaml based on the variable
  values = [
    file("${path.module}/../helm/luxe-app/values-${var.environment}.yaml")
  ]

  # Enforce the environment variable at the Helm level
  set {
    name  = "environment"
    value = var.environment
  }
}
