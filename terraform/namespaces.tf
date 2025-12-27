# System Namespaces
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

# --- Multi-Environment Setup ---

# Development Environment (For feature/* branches)
resource "kubernetes_namespace_v1" "app_dev" {
  metadata {
    name = "luxe-app-dev"
    labels = {
      environment = "dev"
      name        = "luxe-app-dev"
    }
  }
}

# Production Environment (For main branch)
resource "kubernetes_namespace_v1" "app_prod" {
  metadata {
    name = "luxe-app-prod"
    labels = {
      environment = "prod"
      name        = "luxe-app-prod"
    }
  }
}