##########################
# 1. Data Source: Latest Amazon Linux 2023
##########################
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

##########################
# 2. Secrets Manager (Shell)
##########################
resource "aws_secretsmanager_secret" "github_token" {
  name        = "github-runner-token"
  description = "GitHub PAT for EC2 Self Hosted Runner"
  recovery_window_in_days = 0 
}

##########################
# 3. IAM Role for Runner
##########################
resource "aws_iam_role" "runner_role" {
  name = "luxe-github-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "runner_secrets_policy" {
  name = "LuxeRunnerSecretsPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = aws_secretsmanager_secret.github_token.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "runner_secrets_attach" {
  role       = aws_iam_role.runner_role.name
  policy_arn = aws_iam_policy.runner_secrets_policy.arn
}

resource "aws_iam_role_policy_attachment" "runner_ssm_attach" {
  role       = aws_iam_role.runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "runner_profile" {
  name = "luxe-github-runner-profile"
  role = aws_iam_role.runner_role.name
}

##########################
# 4. Launch Template
##########################
resource "aws_launch_template" "runner_lt" {
  name_prefix   = "luxe-runner-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  
  # FIX: Switch to t2.micro (Free Tier Eligible)
  instance_type = "t2.micro" 
  
  iam_instance_profile {
    name = aws_iam_instance_profile.runner_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [module.vpc.default_security_group_id]
  }
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  
  user_data = base64encode(templatefile("${path.module}/user_data_runner.sh", {
    runner_version = "2.321.0" 
    repo_url       = "https://github.com/TalGold01/kubernetes-project"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "luxe-github-runner"
      Project = "LuxeJewelry"
      Backup  = "True"
    }
  }
}

##########################
# 5. Auto Scaling Group
##########################
resource "aws_autoscaling_group" "runner_asg" {
  name                = "luxe-runner-asg"
  vpc_zone_identifier = module.vpc.public_subnets
  
  min_size         = 0
  max_size         = 1
  desired_capacity = 0

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.runner_lt.id
        version            = "$Latest"
      }
      
      # FIX: Only use Free Tier eligible types in override list
      override {
        instance_type = "t3.micro"
      }
      override {
        instance_type = "t2.micro"
      }
    }

    instances_distribution {
      # FIX: Prioritize On-Demand usage (Free Tier applies to On-Demand, not Spot)
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 0 
      spot_allocation_strategy                 = "capacity-optimized"
    }
  }

  tag {
    key                 = "Project"
    value               = "LuxeJewelry"
    propagate_at_launch = true
  }
}