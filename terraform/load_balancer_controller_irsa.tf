# 1. Fetch the official IAM Policy from AWS
# (This prevents us from having to hardcode 300+ lines of JSON)
data "http" "lb_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "lb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy-Luxe"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  policy      = data.http.lb_policy.response_body
}

# 2. Trust Policy for OIDC
data "aws_iam_policy_document" "lb_controller_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      # FIX: Use the replace function to strip "https://" from the URL, matching our other IRSA fix
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

# 3. Create Role
resource "aws_iam_role" "lb_controller_role" {
  name               = "luxe-aws-load-balancer-controller-role"
  assume_role_policy = data.aws_iam_policy_document.lb_controller_trust.json
}

# 4. Attach Policy
resource "aws_iam_role_policy_attachment" "lb_controller_attach" {
  policy_arn = aws_iam_policy.lb_controller_policy.arn
  role       = aws_iam_role.lb_controller_role.name
}