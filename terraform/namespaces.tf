# System Namespaces (CI/CD & GitOps)
resource "kubernetes_namespace_v1" "github" {
  metadata {
    name = "luxe-github"
    labels = {
      name = "luxe-github"
    }
  }
}

resource "kubernetes_namespace_v1" "argo" {
  metadata {
    name = "luxe-argo"
    labels = {
      name = "luxe-argo"
    }
  }
}

# App Namespaces (Multi-Environment)
resource "kubernetes_namespace_v1" "luxe_app_dev" {
  metadata {
    name = "luxe-app-dev"
    labels = {
      name = "luxe-app-dev"
    }
  }
}

resource "kubernetes_namespace_v1" "luxe_app_prod" {
  metadata {
    name = "luxe-app-prod"
    labels = {
      name = "luxe-app-prod"
    }
  }
}
