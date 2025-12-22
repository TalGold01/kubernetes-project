##########################
# VPC Module
##########################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0" 

  name = "luxe-vpc"
  cidr = "10.10.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnets = ["10.10.101.0/24", "10.10.102.0/24"]

  # FinOps: No NAT Gateway
  enable_nat_gateway = false 
  
  # Mandatory for public nodes
  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Project = "luxe-jewelry-store"
    FinOps  = "True"
  }
}

##########################
# EKS Cluster Module
##########################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.21"

  cluster_name    = "luxe-eks"
  cluster_version = "1.32"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  # Auth ConfigMap (Crucial for CodeBuild)
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::349020400385:role/luxe-codebuild-role"
      username = "codebuild"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::349020400385:user/project-admin"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]

  ##########################
  # EKS Managed Node Groups
  ##########################
  eks_managed_node_groups = {
    spot_nodes = {
      subnet_ids = module.vpc.public_subnets
      associate_public_ip_address = true

      # DEMO SETTINGS:
      # We use 3 micros to ensure enough RAM for system pods + your app.
      min_size     = 2
      max_size     = 4
      desired_size = 3 

      capacity_type  = "SPOT"
      instance_types = ["t3.micro"] # Free tier eligible type
      
      labels = {
        role = "spot"
      }
      
      tags = {
        Name = "luxe-spot-node"
      }
    }
  }

  tags = {
    Project = "luxe-jewelry-store"
    FinOps  = "True"
  }
}