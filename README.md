# ☸️ Enterprise Kubernetes Infrastructure & SRE Operations
> **Production-Grade EKS Architecture for the Luxe E-Commerce Platform**

![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326CE5?logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform&logoColor=white)
![Helm](https://img.shields.io/badge/Deployment-Helm-0F1689?logo=helm&logoColor=white)
![Prometheus](https://img.shields.io/badge/Observability-Prometheus_%7C_Grafana-E6522C?logo=prometheus&logoColor=white)

## 📖 SRE Overview
This repository contains the declarative infrastructure and deployment configuration for a highly available, secure, and cost-optimized microservices environment. Built with a focus on **Site Reliability Engineering (SRE)** principles, it leverages Terraform for infrastructure state, Helm for dynamic application releases, and the AWS Secrets Store CSI driver for zero-trust credential management.

## 🏗️ Core Architecture & Engineering Highlights

### 💰 1. FinOps & Cost Optimization
* **Spot Instance Fleet:** Utilizing capacity-optimized `t3.micro` Spot Instances for the EKS node group, achieving up to 70% compute cost reduction.
* **Network Cost Reduction:** Architected a custom VPC with Public/Private subnets but explicitly disabled NAT Gateways (~$30/mo savings), utilizing precise Security Group routing for egress.
* **Scale-to-Zero CI/CD:** Self-hosted GitHub Actions runners operate on EC2 Auto Scaling Groups that automatically scale to 0 when idle.
* **Storage Lifecycle:** Automated S3 Lifecycle policies purge stale deployment artifacts after 7 days to eliminate zombie storage costs.

### 📦 2. Declarative Releases (Helm & Terraform)
* **Dynamic Helm Charts:** Replaced static manifests with a custom Helm chart (`helm/luxe-app/`) to standardize microservice deployments.
* **Environment-Scoped Parity:** Implemented `values-dev.yaml` and `values-prod.yaml` injected dynamically via Terraform's `helm_release` resource, ensuring isolated and repeatable environment scaling.

### 💾 3. Stateful Persistence (EBS & PVCs)
* **Persistent Volume Claims:** Configured AWS EBS-backed StorageClasses with `Retain` reclaim policies to ensure stateful application logs and data survive pod eviction and cluster scaling events.

### 🛡️ 4. Zero-Trust Security
* **AWS Secrets Store CSI Driver:** Completely eliminated native Kubernetes Secrets. Pods authenticate via IAM Roles for Service Accounts (IRSA) to mount AWS Secrets Manager credentials directly as ephemeral volumes.
* **Least Privilege:** Granular IAM policies restrict node and pod access exclusively to required ARNs. No hardcoded tokens exist anywhere in the repository.
* **Network Isolation:** Application layer and database layers are strictly isolated within private subnets.

### 📊 5. Observability & MTTD
* **Kube-Prometheus-Stack:** Fully integrated monitoring and alerting pipeline. Architected automated Grafana dashboards to rapidly detect pod failures, latency spikes, and resource starvation, drastically reducing Mean Time To Detect (MTTD).

---

## 📂 Repository Structure
* `/terraform` - Core IaC (VPC, EKS cluster, IRSA, FinOps configurations, and dynamic Helm releases).
* `/helm/luxe-app` - Custom application chart with environment-scoped values and PVC definitions.
* `/src` - Application source code, Dockerfiles, and build specifications.
* `/docs` - Architecture diagrams, Grafana dashboard exports, and project reports.

---

## 🚀 Deployment Pipeline

### 1. Infrastructure Provisioning
The entire cluster, networking layer, and application Helm chart are deployed concurrently via Terraform.

```bash
cd terraform
terraform init

# Deploy the Dev Environment
terraform apply -var="environment=dev" --auto-approve

# Deploy the Prod Environment
terraform apply -var="environment=prod" --auto-approve

```
2. CI/CD Integration (GitHub Actions)

Changes pushed to the main branch trigger the CI/CD pipeline which automatically:

   1. Scales the self-hosted EC2 runner from 0 to 1.

   2. Builds the Docker image and pushes to immutable ECR tags.

   3. Updates the cluster state and notifies via AWS SNS.

   4. Scales the runner back to 0 upon completion.