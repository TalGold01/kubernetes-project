# The AWS Provider chart now bundles the CSI Driver
resource "helm_release" "csi_secrets_store_aws_provider" {
  name       = "aws-secrets-manager-provider"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  
  set {
    name  = "secrets-store-csi-driver.syncSecret.enabled"
    value = "true"
  }
  
  set {
    name  = "secrets-store-csi-driver.install"
    value = "true"
  }
}