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

  # FinOps: No NAT Gateway.
  # Nodes MUST be in public subnets to reach the internet (ECR/AWS APIs).
  enable_nat_gateway = false 
  
  # FIX: Mandatory for public nodes without NAT Gateway
  # This fixes the "Ec2SubnetInvalidConfiguration" error you saw
  map_public_ip_on_launch = true

  # CRITICAL FOR ALB CONTROLLER:
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
  
  # FinOps Upgrade: Use 1.32 to stay in Standard Support ($0.10/hr)
  # Versions 1.28, 1.29, 1.30, and 1.31 are all in Extended Support ($0.60/hr)
  cluster_version = "1.32"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # Public access is REQUIRED because our nodes (in public subnets) 
  # will talk to the control plane via the public internet endpoint.
  cluster_endpoint_public_access = true

  ##########################
  # EKS Managed Node Groups
  ##########################
  eks_managed_node_groups = {
    spot_nodes = {
      # CRITICAL Fix for FinOps (No NAT GW):
      # We force nodes into Public Subnets so they can pull images from ECR.
      subnet_ids = module.vpc.public_subnets
      
      # Assign public IPs so they can route out to the internet
      associate_public_ip_address = true

      min_size     = 1
      max_size     = 2
      desired_size = 1

      capacity_type  = "SPOT"
      instance_types = ["t3.small"] 
      
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