# EKS Platform Architecture (Terraform-based) — Explanation & Rationale

## 1) Why we are building this platform

We want a Kubernetes platform on AWS that is:

- **Repeatable**: same result every time using Infrastructure as Code (Terraform).
- **Secure by default**: least-privilege access, isolated networking, minimal public exposure.
- **Production-oriented**: supports ingress, storage, scaling, and observability.
- **Modular & maintainable**: VPC/EKS/Add-ons separated so changes are safer and easier to manage.

This platform provides a foundation to run microservices and workloads with:

- Reliable networking and DNS
- Secure workload-to-AWS access (no long-lived secrets)
- Managed ingress via ALB
- Persistent storage via EBS
- Monitoring with Prometheus (+ optional Grafana)
- A clean separation between infrastructure layers

---

## 2) High-level architecture (what exists in AWS)

### Core Infrastructure (Foundation)

1. **VPC**
   - Public subnets (ALB, NAT gateway)
   - Private subnets (EKS worker nodes, pods)
   - Route tables, IGW, NAT, DNS support

2. **EKS Cluster**
   - Managed control plane (AWS-managed)
   - Worker nodes (Managed Node Groups) in **private subnets**
   - Cluster endpoint access (public/private based on your config)

3. **IAM & Security**
   - Node instance role for baseline node permissions
   - OIDC provider for IRSA
   - Security groups controlling north-south and east-west traffic

---

## 3) Kubernetes platform layer (what exists inside the cluster)

### Essential EKS Add-ons (Baseline)

These add-ons are required so the cluster behaves correctly on AWS:

1. **VPC CNI**
   - Assigns VPC IPs to pods
   - Enables pod networking integrated with AWS VPC (ENI/IP management)

2. **CoreDNS**
   - Service discovery inside the cluster
   - Resolves `service.namespace.svc.cluster.local`

3. **kube-proxy**
   - Implements service routing (ClusterIP/NodePort) using iptables/ipvs rules

4. **EBS CSI Driver**
   - Enables dynamic provisioning of EBS volumes from Kubernetes PVCs
   - Required for stateful apps and for Prometheus persistent storage

### Identity & Access (Security)

1. **IRSA (IAM Roles for Service Accounts)**
   - Allows pods to access AWS services securely **without** static access keys
   - Uses Kubernetes service accounts + OIDC trust + STS temporary credentials
   - Critical for components like:
     - AWS Load Balancer Controller
     - EBS CSI Driver (optional depending on your approach/version)
     - External-DNS (if used)
     - Any application needing S3/DynamoDB/etc.

### Ingress (Expose applications safely)

1. **AWS Load Balancer Controller**
   - Watches Kubernetes Ingress objects and creates/manages AWS ALBs
   - Supports:
     - host-based routing (app.example.com)
     - path-based routing (/api, /web)
   - Preferred approach vs creating a separate LoadBalancer per service

### Observability (Monitoring)

1. **Prometheus (kube-prometheus-stack)**
   - Full monitoring system (not just CPU/memory)
   - Stores time-series metrics, supports alerting (Alertmanager) and dashboards (Grafana)
   - Uses a **pull model** scraping `/metrics` endpoints
   - Often backed by persistent volume (EBS) so metrics survive pod restarts

> Note: Metrics Server is lightweight and mainly for HPA. Prometheus is for full monitoring + history + alerts.

---

## 4) Traffic flow (how requests reach your pods)

### External user → application

1. User hits `https://your-domain.com`
2. DNS resolves to an **AWS ALB**
3. ALB forwards traffic using rules defined by Kubernetes **Ingress**
4. Traffic goes to a Kubernetes **Service**
5. Service routes to **Pods** (your application containers)

This is the typical production pattern:
**Internet → ALB → Ingress rules → Service → Pods**

---

## 5) Storage flow (how pods get persistent volumes)

### Stateful workload → EBS volume

1. A pod requests storage via **PVC**
2. Kubernetes consults the **StorageClass**
3. **EBS CSI Driver** provisions a new EBS volume
4. Volume attaches to the node hosting the pod
5. Pod mounts the volume and uses it

Important limitation:

- EBS volumes are generally **single-node attachment** (good for single-writer workloads).

---

## 6) Identity flow (how pods securely access AWS)

### Pod → AWS API (no secrets)

1. Pod runs under a Kubernetes **ServiceAccount**
2. ServiceAccount is annotated with an IAM Role ARN
3. Pod receives a projected service account token (JWT)
4. AWS STS validates the token using the cluster’s **OIDC provider**
5. STS returns temporary credentials for the IAM Role
6. Pod uses those credentials to call AWS services

This enables:

- Least privilege per workload
- No static access keys
- Clear auditability in AWS CloudTrail

---

## 7) Terraform modular design (why modules)

We split Terraform into modules to keep concerns separated:

### VPC Module

- Networking foundation (subnets, routes, NAT)
Why:
- Networking changes are high-impact; isolate them.
- Reuse across environments.

### EKS Module

- Cluster control plane, node groups, cluster security baseline
Why:
- Cluster lifecycle is distinct from app/ingress lifecycle.
- Allows independent upgrades and safe rollbacks.

### Add-ons Module

- Managed add-ons and platform services (CNI, CoreDNS, kube-proxy, CSI, LB controller, Prometheus)
Why:
- Add-ons evolve faster than core infrastructure.
- Reduces blast radius when upgrading observability or ingress components.

### Root Module

- Wires everything together:
  - passes VPC outputs → EKS
  - passes EKS outputs → Add-ons
  - centralizes environment configuration and backend state

---

## 8) Why this approach is a good “platform”

This platform gives you:

- A secure network posture (private nodes, controlled ingress)
- Standard ingress pattern (ALB + Ingress resources)
- Secure workload IAM (IRSA)
- Persistent storage for stateful components (EBS CSI)
- Production observability (Prometheus stack)
- Terraform-driven repeatability and environment parity

---

## 9) What we can deploy on top of it

Once the platform is in place, you can safely add:

- Microservices (Deployments + Services + Ingress)
- Databases (StatefulSets + PVCs)
- CI/CD agents (GitHub Actions runners, ArgoCD, etc.)
- External-DNS + cert-manager (for managed DNS + TLS automation)
- HPA + cluster autoscaler (scaling)

---

## 10) Glossary (quick reference)

- **VPC**: AWS private network boundary
- **Subnet**: segmented network range (public/private)
- **EKS**: managed Kubernetes control plane
- **Node Group**: worker nodes running pods
- **Add-on**: operational component inside cluster
- **Ingress**: rules for HTTP/HTTPS routing into cluster
- **ALB**: AWS Application Load Balancer
- **CSI Driver**: plugin for storage provisioning
- **IRSA**: pod-level IAM via service account and OIDC
- **Prometheus**: monitoring + alerting time-series system
