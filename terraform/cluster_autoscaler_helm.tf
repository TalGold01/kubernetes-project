resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.37.0" # Stable version compatible with EKS 1.28+

  # 1. Tell the autoscaler which cluster to manage (It looks for ASG tags)
  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  # 2. Set the AWS Region
  set {
    name  = "awsRegion"
    value = "us-east-1"
  }

  # 3. RBAC & Service Account Configuration
  set {
    name  = "rbac.serviceAccount.create"
    value = "true"
  }
  
  set {
    name  = "rbac.serviceAccount.name"
    # This MUST match the service account name used in your IRSA trust policy
    value = "cluster-autoscaler"
  }

  # 4. The "Magic Link" (IRSA)
  # This annotation grants the pod the IAM permissions defined in cluster_autoscaler_irsa.tf
  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler.arn
  }

  # 5. FinOps & Performance Tuning
  # Scale down empty nodes after just 2 minutes (Default is usually 10m)
  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = "2m" 
  }

  # 6. Ensure the pod doesn't get evicted easily
  set {
    name  = "extraArgs.expander"
    value = "least-waste" # Prioritize nodes that will be most utilized after scaling
  }
}