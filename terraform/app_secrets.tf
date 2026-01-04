resource "aws_secretsmanager_secret" "app_config" {
  name        = "luxe-app-config"
  description = "Configuration secrets for the Luxe App"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app_config_val" {
  secret_id     = aws_secretsmanager_secret.app_config.id
  secret_string = jsonencode({
    "DB_PASSWORD" = "changeme123"
    "API_KEY"     = "123456"
  })
}

resource "aws_iam_role" "app_sa_role" {
  name = "luxe-app-sa-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          # STRICT MATCHING: Only allows the 'default' service account in 'luxe-app' namespace
          "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:luxe-app:default"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "app_secret_access" {
  name = "LuxeAppSecretAccess"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = aws_secretsmanager_secret.app_config.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_secret_attach" {
  role       = aws_iam_role.app_sa_role.name
  policy_arn = aws_iam_policy.app_secret_access.arn
}