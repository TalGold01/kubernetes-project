Luxe Jewelry Store - AWS Cloud Migration Project

📖 Project Overview

This project demonstrates a full migration of a legacy workload to a cloud-native architecture on AWS. It leverages Infrastructure as Code (Terraform), Kubernetes (EKS), and GitOps principles to achieve a scalable, secure, and cost-optimized deployment.

🏗️ Architecture Architecture

1. Infrastructure (Terraform)

Compute: Amazon EKS v1.32 (Standard Support) using Spot Instances (t3.micro/t3.small) for 70% cost reduction.

Networking: Custom VPC with Public/Private subnets. NAT Gateways are disabled to minimize Free Tier costs; nodes utilize Public IPs for egress.

CI/CD Agents: Self-Hosted GitHub Runners on EC2, managed by an Auto Scaling Group (ASG) and Launch Template.

Storage: * ECR: Private container registry with immutable tags.

S3 + CloudFront: Hosting for static frontend assets (Bonus).

AWS Backup: Automated daily retention for EC2 instances.

2. CI/CD Pipelines

We implemented two parallel pipelines to demonstrate flexibility:

GitHub Actions:

Runs on self-hosted EC2 runners.

Builds Docker image -> Pushes to ECR -> Deploys to EKS.

Sends SNS notifications on status.

AWS CodePipeline:

Native AWS integration.

CodeBuild 1: Builds & Pushes Docker image.

CodeBuild 2: Authenticates via IAM and deploys manifests to EKS.

3. Kubernetes Configuration

Ingress: AWS Load Balancer Controller (ALB) for external access.

Scaling: Cluster Autoscaler + Metrics Server for HPA.

Secrets: AWS Secrets Store CSI Driver to mount secrets (DB passwords) directly from AWS Secrets Manager into Pods.

Namespaces: luxe-app, luxe-github, luxe-argo.

🚀 How to Deploy

Prerequisites

AWS CLI configured.

Terraform v1.0+.

GitHub Personal Access Token (PAT).

Step 1: Infrastructure Provisioning

cd terraform
terraform init
terraform apply --auto-approve


Step 2: Configuration

Inject GitHub Token:

aws secretsmanager put-secret-value --secret-id github-runner-token --region us-east-1 --secret-string "{\"token\":\"ghp_YOUR_TOKEN\"}"


Activate Runner: Scale ASG luxe-runner-asg to 1.

Authorize Pipeline: Update Pending Connection in AWS Developer Tools.

Step 3: Application Deployment

Push changes to main branch to trigger the pipeline.

git push origin main


💰 FinOps & Optimization Highlights

Zero-Cost Idle: Runners scale to 0 when not in use.

Spot Strategy: Usage of capacity-optimized allocation strategy for EKS nodes.

Storage cleanup: S3 Lifecycle policies delete artifacts after 7 days.

Network: Elimination of NAT Gateway charges (~$30/mo savings).

🛡️ Security Measures

No Hardcoded Secrets: All tokens fetched dynamically from Secrets Manager.

Least Privilege: IAM roles scoped strictly to required resources (IRSA).

Network Isolation: Database and App layers isolated in private subnets (logic ready