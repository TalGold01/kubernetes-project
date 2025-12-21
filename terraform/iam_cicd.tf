##########################
# CodePipeline Role
##########################
resource "aws_iam_role" "codepipeline_role" {
  name = "luxe-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "codepipeline.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "luxe-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:GetBucketVersioning"]
        Resource = [aws_s3_bucket.codepipeline_bucket.arn, "${aws_s3_bucket.codepipeline_bucket.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["codestar-connections:UseConnection"]
        Resource = aws_codestarconnections_connection.github.arn
      }
    ]
  })
}

##########################
# CodeBuild Role
##########################
resource "aws_iam_role" "codebuild_role" {
  name = "luxe-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "codebuild.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "luxe-codebuild-policy"
  role = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents",
          "s3:GetObject", "s3:PutObject",
          "ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:PutImage", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload",
          "eks:DescribeCluster"
        ]
        Resource = "*"
      }
    ]
  })
}