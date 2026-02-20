# 🌐 Terraform VPC Module (EKS Ready)

## 📌 Overview

This setup uses a **Terraform child module** to create a production-ready VPC for EKS with:

* Public and Private subnets
* Internet Gateway (IGW)
* NAT Gateway
* Route tables
* Subnet tagging for Kubernetes

---

## 🧠 Architecture Summary

* **VPC CIDR**: `10.0.0.0/16`
* **AZs**: 2 (`us-east-1a`, `us-east-1b`)
* **Public Subnets**:

  * `10.0.0.0/24`
  * `10.0.1.0/24`
* **Private Subnets**:

  * `10.0.100.0/24`
  * `10.0.101.0/24`

### Routing

* Public subnets → Internet Gateway
* Private subnets → NAT Gateway (outbound only)

---

## ⚙️ Module Usage

### Root Module

```hcl
module "network" {
  source = "./modules/vpc"

  name = "${var.project_name}-vpc"

  vpc_cidr = var.vpc_cidr
  azs      = var.azs

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  cluster_name = var.cluster_name

  tags = var.tags
}
```

---

## 📥 Variables (example)

```hcl
aws_region   = "us-east-1"
project_name = "eks-lab"
cluster_name = "demo-eks"

vpc_cidr = "10.0.0.0/16"

azs = ["us-east-1a", "us-east-1b"]

public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnets = ["10.0.100.0/24", "10.0.101.0/24"]

enable_nat_gateway = true
single_nat_gateway = true

tags = {
  Project = "eks-lab"
  Owner   = "Ahmed"
}
```

---

## 🔄 What the Module Creates (Internally)

The VPC module automatically provisions:

* `aws_vpc`
* `aws_subnet` (public + private)
* `aws_internet_gateway`
* `aws_nat_gateway` + `aws_eip`
* `aws_route_table` + routes + associations

---

## 🏷️ Kubernetes Subnet Tags

Required for AWS Load Balancer integration:

* Public: `kubernetes.io/role/elb = 1`
* Private: `kubernetes.io/role/internal-elb = 1`
* Cluster association:

  * `kubernetes.io/cluster/<cluster_name> = shared`

---

## ▶️ Usage

```bash
terraform init
terraform plan
terraform apply
```

---

## ⚠️ Notes

* Use **private subnets for EKS nodes** (recommended)
* `single_nat_gateway = true` → cheaper (dev/lab)
* Use `false` → NAT per AZ (production)

---

## 🧠 Key Concept

You define the **architecture (inputs)**,
the module builds the **AWS resources (implementation)**.
