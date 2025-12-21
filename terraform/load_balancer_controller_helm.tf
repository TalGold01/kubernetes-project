resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2" # Stable version

  # 1. Cluster Name is required
  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  # 2. Service Account setup (The "Magic Link" to IAM)
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.lb_controller_role.arn
  }

  # 3. Network details
  set {
    name  = "region"
    value = "us-east-1"
  }
  
  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }
}
