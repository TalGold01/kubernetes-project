resource "kubernetes_namespace_v1" "github" {
  metadata {
    name = "luxe-github"
    labels = {
      name = "luxe-github"
    }
  }
}

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = "luxe-app"
    labels = {
      name = "luxe-app"
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