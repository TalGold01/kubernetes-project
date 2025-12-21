##########################
# 1. GitHub Connection (CodeStar)
##########################
# TRAP: After 'terraform apply', you MUST go to AWS Console -> Developer Tools -> Settings -> Connections
# and click "Update Pending Connection" to authorize access to your GitHub.
resource "aws_codestarconnections_connection" "github" {
  name          = "luxe-github-connection"
  provider_type = "GitHub"
}

##########################
# 2. S3 Artifact Bucket
##########################
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket_prefix = "luxe-codepipeline-"
  force_destroy = true
}

##########################
# 3. CodeBuild: Build & Push (Docker)
##########################
resource "aws_codebuild_project" "build" {
  name          = "luxe-build-push"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "15"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true # Required for Docker

    environment_variable {
      name  = "ECR_REPO_URL"
      value = aws_ecr_repository.luxe_repo.repository_url
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "us-east-1"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec_build.yml"
  }
}

##########################
# 4. CodeBuild: Deploy (Kubectl)
##########################
resource "aws_codebuild_project" "deploy" {
  name          = "luxe-deploy-eks"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "15"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type            = "LINUX_CONTAINER"
    
    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = module.eks.cluster_name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec_deploy.yml"
  }
}

##########################
# 5. CodePipeline
##########################
resource "aws_codepipeline" "pipeline" {
  name     = "luxe-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "TalGold01/kubernetes-project" # Update this if using a different repo
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Build" # Using CodeBuild to run kubectl
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output", "build_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.deploy.name
      }
    }
  }
  
  tags = {
    Project = "LuxeJewelry"
  }
}