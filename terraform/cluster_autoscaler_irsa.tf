# 1. Define the Policy explicitly
# This gives the autoscaler permission to adjust the ASG size
resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "LuxeClusterAutoscalerPolicy"
  path        = "/"
  description = "Permissions for Cluster Autoscaler to manage EC2 ASGs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes"
        ]
        Resource = "*"
      }
    ]
  })
}

# 2. Trust Policy for OIDC (The "Assume Role" logic)
# This allows the Kubernetes Service Account to act as this IAM Role
data "aws_iam_policy_document" "cluster_autoscaler_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      # FIX: We strip the "https://" from the OIDC URL for the IAM condition
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
  }
}

# 3. Create the Role
resource "aws_iam_role" "cluster_autoscaler" {
  name               = "luxe-cluster-autoscaler-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_trust.json
}

# 4. Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
  role       = aws_iam_role.cluster_autoscaler.name
}