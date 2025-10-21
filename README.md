# Ship-a-Service: End-to-End CI/CD on Managed Kubernetes
Launch EKS Cluster with Terraform
1️⃣ Set AWS credentials

Export your AWS keys and region:

export AWS_ACCESS_KEY_ID=<your_access_key>
export AWS_SECRET_ACCESS_KEY=<your_secret_key>
export AWS_DEFAULT_REGION=<your_region>


Check they are valid:

aws sts get-caller-identity

2️⃣ Make sure your SSH key exists

If you want SSH access to nodes:

Check existing keys:

aws ec2 describe-key-pairs


Create key if missing:

aws ec2 create-key-pair --key-name ahmedkey --query 'KeyMaterial' --output text > ahmedkey.pem
chmod 400 ahmedkey.pem


Update Terraform variable ssh_key_name = "ahmedkey"

3️⃣ Initialize Terraform
terraform init

4️⃣ Plan deployment
terraform plan


Check that Terraform plans to create your VPC, subnets, EKS cluster, node groups, and ECR repository.

5️⃣ Apply deployment
terraform apply


Type yes when prompted.

Terraform will create all resources, including node group using your SSH key.
**Author:** Ahmed Marzougui (@MarzouguiAhmed9)  
**Challenge:** DevOps/Technical Writer Position  
**Status:** Phase 1 Complete - Infrastructure Provisioning ✅

---

## 📋 Overview

This project demonstrates production-ready infrastructure provisioning for a Kubernetes-based microservices platform on AWS EKS, showcasing infrastructure-as-code best practices and technical documentation skills.

**Goal:** Build complete CI/CD pipeline: `commit → container → security checks → Helm deploy → production`

**Current Status:** Infrastructure foundation complete (Phase 1 of 7)

---

## 🎯 What's Been Built (Phase 1)

### Infrastructure Components

✅ **Network Layer**
- Custom VPC (10.0.0.0/16)
- 2 Public subnets across different Availability Zones
- Multi-AZ high availability setup

✅ **Kubernetes Cluster**
- AWS EKS v1.28 managed cluster
- Auto-scaling node group (1-3 nodes)
- t3.medium instances (2 vCPU, 4GB RAM)

✅ **Container Registry**
- Private ECR repository
- Image scanning enabled
- Mutable tags for development

✅ **IAM & Security**
- EKS cluster role with minimal permissions
- Node group IAM role
- GitLab CI OIDC integration prepared

---

## 🏗️ Architecture Diagram

```
┌────────────────────────────────────────────────────────────┐
│                    AWS Region: us-east-1                   │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │              VPC (10.0.0.0/16)                       │ │
│  │                                                      │ │
│  │   ┌────────────────┐      ┌────────────────┐        │ │
│  │   │  Subnet A      │      │  Subnet B      │        │ │
│  │   │  10.0.1.0/24   │      │  10.0.2.0/24   │        │ │
│  │   │  us-east-1a    │      │  us-east-1b    │        │ │
│  │   └───────┬────────┘      └───────┬────────┘        │ │
│  │           └────────┬───────────────┘                 │ │
│  │                    │                                 │ │
│  │   ┌────────────────▼─────────────────┐               │ │
│  │   │  EKS Cluster: ship-a-service     │               │ │
│  │   │  Version: 1.28                   │               │ │
│  │   │                                  │               │ │
│  │   │  Node Group:                     │               │ │
│  │   │  • Min: 1 node                   │               │ │
│  │   │  • Desired: 2 nodes              │               │ │
│  │   │  • Max: 3 nodes                  │               │ │
│  │   │  • Type: t3.medium               │               │ │
│  │   └──────────────────────────────────┘               │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │  ECR Repository: ship-a-service                      │ │
│  │  • Image Scanning: Enabled                           │ │
│  │  • Encryption: AES-256                               │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │  IAM Roles                                           │ │
│  │  • EKS Cluster Role                                  │ │
│  │  • Node Group Role                                   │ │
│  │  • GitLab CI Role (OIDC)                             │ │
│  └──────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | ≥ 1.5, < 2.0 | Infrastructure provisioning |
| AWS CLI | ≥ 2.0 | AWS authentication |
| kubectl | ≥ 1.28 | Kubernetes management |

### AWS Setup

**1. Create AWS Account**
- Free tier at [aws.amazon.com/free](https://aws.amazon.com/free)

**2. Create IAM User**
Required policies:
- `AmazonEKSClusterPolicy`
- `AmazonEC2FullAccess`
- `AmazonECRFullAccess`
- `IAMFullAccess`

**3. Create EC2 Key Pair**
```bash
aws ec2 create-key-pair \
  --key-name ahmedkey \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/ahmedkey.pem

chmod 400 ~/.ssh/ahmedkey.pem
```

---

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/MarzouguiAhmed9/ship-a-service-end-to-end-ci-cd-on-managed-kubernetes.git
cd ship-a-service-end-to-end-ci-cd-on-managed-kubernetes/infra/terraform
```

### 2. Configure AWS Credentials
```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_DEFAULT_REGION="us-east-1"

# Verify
aws sts get-caller-identity
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Review Configuration

**Create `terraform.tfvars`:**
```hcl
# Cluster
cluster_name = "ship-a-service"
region       = "us-east-1"

# Network
vpc_cidr      = "10.0.0.0/16"
subnet_a_cidr = "10.0.1.0/24"
subnet_b_cidr = "10.0.2.0/24"
az_a          = "us-east-1a"
az_b          = "us-east-1b"

# Nodes
node_desired  = 2
node_min      = 1
node_max      = 3
node_type     = "t3.medium"

# SSH
ssh_key_name  = "ahmedkey"

# Environment
env = "dev"
```

### 5. Deploy Infrastructure
```bash
# Preview changes
terraform plan

# Apply (15-20 minutes)
terraform apply
# Type: yes
```

### 6. Connect to Cluster
```bash
# Configure kubectl
aws eks update-kubeconfig \
  --region us-east-1 \
  --name ship-a-service

# Verify
kubectl get nodes
```

**Expected Output:**
```
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-1-xxx.ec2.internal    Ready    <none>   5m    v1.28.x
ip-10-0-2-xxx.ec2.internal    Ready    <none>   5m    v1.28.x
```

---

## 📁 Terraform Structure

```
infra/terraform/
├── main.tf          # VPC, subnets, EKS cluster, ECR, IAM roles
├── variables.tf     # Input variables
├── outputs.tf       # Cluster endpoint, ECR URL
├── versions.tf      # Provider versions (AWS ~5.0)
└── terraform.tfvars # Your configuration values (not committed)
```

### Key Resources Created

**Network (3 resources):**
- `aws_vpc.main` - VPC with CIDR 10.0.0.0/16
- `aws_subnet.subnet_a` - Public subnet in AZ-A
- `aws_subnet.subnet_b` - Public subnet in AZ-B

**EKS (via module - ~20 resources):**
- EKS control plane
- Managed node group with auto-scaling
- Security groups
- IAM roles and policies

**Registry (1 resource):**
- `aws_ecr_repository.app` - Private container registry

**IAM (2 resources):**
- `aws_iam_role.gitlab_ci_role` - GitLab CI OIDC role
- Policy attachments for ECR and EKS access

---

## 📊 Outputs

After deployment, retrieve important values:

```bash
# Get all outputs
terraform output

# ECR repository URL
terraform output ecr_repository_url
# Output: xxxxx.dkr.ecr.us-east-1.amazonaws.com/ship-a-service

# Cluster name
terraform output cluster_name
# Output: ship-a-service

# Cluster endpoint
terraform output cluster_endpoint
# Output: https://xxxxx.eks.amazonaws.com
```

---

## 🔐 Security Features

### IAM Least Privilege

**EKS Cluster Role:**
```
Managed Policies:
  ✓ AmazonEKSClusterPolicy (AWS managed)
  ✓ AmazonEKSVPCResourceController (AWS managed)
```

**Node Group Role:**
```
Managed Policies:
  ✓ AmazonEKSWorkerNodePolicy
  ✓ AmazonEKS_CNI_Policy
  ✓ AmazonEC2ContainerRegistryReadOnly
```

**GitLab CI Role (OIDC):**
```
Assume Role: Web Identity via GitLab OIDC
Permissions:
  ✓ AmazonEC2ContainerRegistryPowerUser (push images)
  ✓ AmazonEKSClusterPolicy (deploy to cluster)
  
Condition: project_path:your-group/your-project:*
```

### Encryption
- ✅ ECR images encrypted at rest (AES-256)
- ✅ EKS control plane encrypted by default
- ✅ No hardcoded credentials (uses AWS IAM)

---

## 💰 Cost Estimate

| Resource | Quantity | Cost/Hour | Monthly Cost |
|----------|----------|-----------|--------------|
| EKS Control Plane | 1 | $0.10 | $73.00 |
| t3.medium nodes | 2 | $0.0416 | $59.90 |
| ECR Storage | <1 GB | - | $0.10 |
| **TOTAL** | | | **~$133/month** |

### Cost Optimization

**For Development:**
```hcl
# Scale down to 1 node
node_desired = 1
node_min     = 1
node_max     = 1

# Use smaller instance
node_type = "t3.small"  # $0.0208/hour (~50% savings)

# Estimated savings: ~$30/month
```

**Note:** EKS control plane ($73/month) is NOT free tier eligible.

---

## 🔧 Troubleshooting

### Issue: Key Pair Not Found
```
Error: The key pair 'ahmedkey' does not exist
```

**Fix:**
```bash
aws ec2 create-key-pair --key-name ahmedkey \
  --query 'KeyMaterial' --output text > ~/.ssh/ahmedkey.pem
chmod 400 ~/.ssh/ahmedkey.pem
terraform apply
```

### Issue: Provider Version Error
```
Error: Unsupported block type "elastic_gpu_specifications"
```

**Fix:**
```bash
rm -rf .terraform .terraform.lock.hcl
terraform init -upgrade
```

### Issue: kubectl Connection Failed
```
Error: Unable to connect to the server
```

**Fix:**
```bash
aws eks update-kubeconfig --name ship-a-service --region us-east-1
kubectl get svc
```

### Useful Commands

```bash
# Check Terraform state
terraform state list
terraform show

# AWS verification
aws eks describe-cluster --name ship-a-service
aws ecr describe-repositories

# Kubernetes checks
kubectl get nodes
kubectl get pods --all-namespaces
kubectl cluster-info
```

---

## 🧹 Cleanup

### Destroy Infrastructure

```bash
cd infra/terraform

# Preview
terraform plan -destroy

# Destroy (10-15 minutes)
terraform destroy
# Type: yes
```

### Manual Cleanup (if needed)

```bash
# Delete ECR images first
aws ecr batch-delete-image \
  --repository-name ship-a-service \
  --image-ids imageTag=latest

# Delete stuck security groups
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=<vpc-id>" \
  --query 'SecurityGroups[*].GroupId' \
  --output text | xargs -I {} aws ec2 delete-security-group --group-id {}
```

---


## 💰 Cost Guardrails
terraform refresh && terraform output cost_report

## 📚 Project Structure

```
ship-a-service-end-to-end-ci-cd-on-managed-kubernetes/
│
├── infra/terraform/          ✅ COMPLETE
│   ├── main.tf              # Infrastructure definitions
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── versions.tf          # Provider versions
│   └── terraform.tfvars     # Configuration (gitignored)
│
├── app/                      ⏳ NEXT PHASE
│   ├── src/server.py        # HTTP service
│   ├── tests/               # Unit tests
│   ├── Dockerfile           # Multi-stage build
│   └── README.md
│
├── charts/app/               ⏳ FUTURE
│   ├── Chart.yaml
│   ├── values.dev.yaml
│   ├── values.prod.yaml
│   └── templates/
│
├── .github/workflows/        ⏳ FUTURE
│   ├── pr-checks.yml
│   └── deploy.yml
│
└── README.md                 ✅ This file
```

---

## 📖 Next Steps

### Phase 2: Ansible (Planned)
- Configure CI runner VM
- Install Docker, kubectl, Helm
- Setup OIDC authentication

### Phase 3: Application (Planned)
- Simple HTTP server with `/healthz`
- Multi-stage Dockerfile
- Unit tests

### Phase 4: Helm Chart 


Chart with dev/prod values

HPA, probes, ingress

Rollout strategy

1️⃣ Create the namespace

kubectl create ns dev


2️⃣ Create the private Docker Hub secret

kubectl create secret docker-registry regcred \
  --docker-username=ahmed20007 \
  --docker-password=SaidaHamdouni2000! \
  --docker-server=https://index.docker.io/v1/ \
  --namespace dev


3️⃣ Deploy the application with Helm

helm upgrade --install app-dev ./ \
  -f values.dev.yaml \
  --namespace dev \
  --atomic \
  --wait \
  --timeout 5m


4️⃣ Check that the pods are Running

kubectl get pods -n dev


5️⃣ Check the service

kubectl get svc -n dev


Note the name and ClusterIP to test internal access.

6️⃣ Test the service from a temporary pod

kubectl run testpod -i --tty --rm --image=busybox --restart=Never -n dev -- sh


Then, inside this pod:

wget -q -O- http://app-dev.dev.svc.cluster.local:8080/healthz


You should see:

{"SYS_ENV":"helloworld","status":"ok"}


7️⃣ Check the HPA

kubectl get hpa -n dev -w


HPA shows REPLICAS, CPU %, and will scale pods if CPU exceeds 50%.

8️⃣ Test HPA under load

kubectl run load-gen -i --tty --rm --image=busybox --restart=Never -- sh
while true; do wget -q -O- http://app-dev.dev.svc.cluster.local:8080/healthz; done


You should see the number of pods increase in HPA if CPU usage rises.

9️⃣ Automatic rollback

If the deployment fails probes or does not become ready:

helm upgrade --install app-dev ./ -f values.dev.yaml --namespace dev --atomic


Helm will automatically roll back to the previous stable version.


### Phase 5: CI/CD (Planned)
GitHub Actions CI Pipeline Testing

This guide explains how to test the CI workflow for this repository using a test branch and pull request. The workflow includes: Go lint & tests, Docker build & Trivy scan, Terraform fmt/validate/plan, Helm lint/unit tests, and TFSEC IaC security scan.

1️⃣ Create a test branch
git siwtch test-ci



2️⃣ Make a small change to trigger CI
# Example: add a comment
echo "// trigger CI test" >> app/src/main.go
git add app/src/main.go
git commit -m "Test CI workflow"
git push origin test-ci

3️⃣ Open a Pull Request

Go to GitHub → your repo → “Pull Requests” → “New pull request”

Base: main

Compare: test-ci

This automatically triggers the workflow because it runs on pull_request to main.

4️⃣ Check workflow run

Go to the Actions tab → click the latest run → view logs for each step:

1️⃣ Checkout repository
2️⃣ Setup Go
3️⃣ Install dependencies
4️⃣ Go lint
5️⃣ Run unit tests
6️⃣ Docker build
7️⃣ Trivy vulnerability scan
8️⃣ Upload Trivy SARIF results
9️⃣ Setup Terraform
🔟 Terraform Init
1️⃣1️⃣ Terraform fmt check
1️⃣2️⃣ Terraform validate
1️⃣3️⃣ Terraform plan
1️⃣4️⃣ Helm lint
1️⃣5️⃣ Install Helm unittest plugin
1️⃣6️⃣ Helm unit tests
1️⃣7️⃣ Install tfsec
1️⃣8️⃣ TFSEC IaC security scan
---

## 📊 Progress Tracker

| Phase | Component | Status | Progress |
|-------|-----------|--------|----------|
| 1 | Infrastructure (Terraform) | ✅ Complete | 100% |
| 2 | Build Host (Ansible) | ⏳ Planned | 0% |
| 3 | Application (Docker) | ⏳ Planned | 0% |
| 4 | Helm Deployment | ⏳ Planned | 0% |
| 5 | CI/CD Pipeline | ⏳ Planned | 0% |
| 6 | Security & Observability | ⏳ Planned | 0% |
| 7 | Documentation | 🚧 In Progress | 50% |
| **OVERALL** | | | **15%** |

---

## 🎓 Skills Demonstrated

**Infrastructure as Code:**
- ✅ Terraform module usage (EKS v18.29.0)
- ✅ AWS provider configuration (~v5.0)
- ✅ Variable management
- ✅ Output definitions

**AWS Services:**
- ✅ EKS cluster provisioning
- ✅ VPC and subnet design
- ✅ ECR repository management
- ✅ IAM roles and policies
- ✅ OIDC federation setup

**Kubernetes:**
- ✅ Managed node groups
- ✅ kubectl configuration
- ✅ Cluster connectivity

**Documentation:**
- ✅ Clear README structure
- ✅ Code examples with explanations
- ✅ Troubleshooting guides
- ✅ Architecture diagrams

---

## 🤝 Contact

**Ahmed Marzougui**  
GitHub: [@MarzouguiAhmed9](https://github.com/MarzouguiAhmed9)

---

## 📝 Notes

- This is Phase 1 of a 7-phase DevOps challenge project
- Infrastructure is production-sensible but optimized for demonstration
- All costs are estimates based on us-east-1 pricing (October 2024)
- GitLab OIDC configuration requires project-specific updates

---

**Last Updated:** 2024-10-18 13:29:31 UTC  
**Version:** 1.0.0  
**Status:** Phase 1 Complete ✅