# 📘 Comprehensive Project Report: AWS Migration & DevOps

**Student:** Tal  
**Project:** Luxe Jewelry Store Migration  
**Date:** December 2025  

---

## 1. Introduction

The goal of this project was to migrate a legacy application to a cloud-native architecture on AWS using industry best practices. We focused heavily on **FinOps (Cost Optimization)**, **Security**, and **Infrastructure as Code (IaC)**.

---

## 2. Infrastructure Layer (Terraform)

We utilized Terraform to provision all resources, ensuring reproducibility and clean code.

### 2.1 EKS Cluster & Networking (`eks.tf`)
* **VPC Design:** Created a custom VPC with Public and Private subnets.
* **FinOps Decision:** We intentionally **disabled NAT Gateways** (saving ~$30/month). To allow nodes to download images without a NAT, we configured them with Public IPs in public subnets, secured via Security Groups.
* **EKS Setup:** Deployed EKS Version **1.32** to utilize Standard Support pricing.
* **Compute:** We utilized **Spot Instances** (`t3.micro`) for the Node Group, reducing compute costs by approximately 70% compared to On-Demand pricing.

### 2.2 Self-Hosted CI/CD Agents (`runners.tf`)
* **Requirement:** Run pipelines inside the private cloud environment.
* **Implementation:** Created an **Auto Scaling Group (ASG)** for GitHub Runners.
* **Automation:** Developed a `user_data` script that installs Docker, fetches the GitHub Registration Token from **AWS Secrets Manager** securely at runtime, and registers the runner.
* **Cost Strategy:** The ASG is set to `min_size=0` by default, ensuring we pay $0 when not testing.

### 2.3 Storage & Backups (`backup.tf`, `ecr.tf`, `website.tf`)
* **ECR:** Created a private Elastic Container Registry with immutable image tags.
* **AWS Backup:** Implemented a Backup Plan that automatically snapshots any EC2 instance tagged with `Backup = True` daily, with a 7-day retention policy.
* **S3 Static Site:** Created an S3 bucket with CloudFront Origin Access Control (OAC) to serve the frontend securely via HTTPS (Bonus Task).

---

## 3. Application Configuration (Kubernetes)

We transitioned from `minikube` manifests to production-grade EKS manifests.

* **Secrets Management:** We installed the **Secrets Store CSI Driver** and **AWS Provider**. This allows our Pods to mount secrets (like DB passwords) directly from AWS Secrets Manager as files, preventing secrets from being exposed in Environment Variables.
* **Ingress:** We deployed the **AWS Load Balancer Controller** via Helm. This automatically provisions an Application Load Balancer (ALB) when we deploy our `ingress.yaml`.
* **Scaling:** We configured the **Cluster Autoscaler** (Infrastructure scaling) and **Metrics Server** (Pod scaling) to handle traffic spikes.

---

## 4. CI/CD Pipelines

We implemented a "Hybrid" approach, satisfying both project requirements.

### 4.1 GitHub Actions (Primary)
* **Workflow:** `.github/workflows/deploy.yaml`
* **Process:**
    1.  Triggers on Push to `main`.
    2.  Runs on our **Self-Hosted EC2 Runner**.
    3.  Builds Docker Image -> Pushes to ECR.
    4.  Updates `kubeconfig` -> Runs `kubectl apply` to EKS.
    5.  Sends Success/Failure notifications to **AWS SNS**.

### 4.2 AWS CodePipeline (Section 2)
* **Infrastructure:** Defined in `cicd.tf`.
* **Flow:**
    * **Source:** Connects to GitHub via AWS CodeStar.
    * **Build:** AWS CodeBuild compiles the Docker image (`buildspec_build.yml`).
    * **Deploy:** AWS CodeBuild applies manifests to EKS (`buildspec_deploy.yml`).
* **Permissions:** We mapped the CodeBuild IAM Role to the `system:masters` group in Kubernetes (`aws-auth` ConfigMap) to allow deployment access.

---

## 5. Security & Best Practices

1.  **No Hardcoded Secrets:** We used `aws_secretsmanager_secret` to manage tokens. Terraform creates the infrastructure, but the actual secret values are injected manually or via CLI, ensuring they are never committed to Git.
2.  **Least Privilege:** All IAM Roles (IRSA) are scoped strictly. For example, the Load Balancer Controller only has permissions related to ELB operations.
3.  **State Management:** We used `.gitignore` to ensure `terraform.tfstate` is never pushed to the repository.

---

## 6. Conclusion

This architecture represents a production-ready, cost-efficient environment. By combining Spot Instances, auto-scaling runners, and managed Kubernetes, we achieved high availability with minimal operational overhead.
