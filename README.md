# 🚀 Ship-a-Service: End-to-End CI/CD on Managed Kubernetes

A production-ready reference implementation for deploying containerized applications on AWS EKS with full CI/CD automation, infrastructure as code, and observability.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Phase 1: Infrastructure Setup](#phase-1-infrastructure-setup)
- [Phase 2: CI Runner Configuration](#phase-2-ci-runner-configuration)
- [Phase 3: Application](#phase-3-application)
- [Phase 4: Helm Chart](#phase-4-helm-chart)
- [Phase 5: CI/CD Pipelines](#phase-5-cicd-pipelines)
- [Phase 6: Security & Secrets](#phase-6-security--secrets)
- [Phase 7: Observability](#phase-7-observability)
- [Cost Management](#cost-management)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

**Ship-a-Service** demonstrates enterprise-grade deployment patterns including:

- ✅ Infrastructure as Code (Terraform)
- ✅ Managed Kubernetes (AWS EKS)
- ✅ Container Registry (AWS ECR)
- ✅ GitOps CI/CD (GitHub Actions)
- ✅ OIDC-based Authentication (no long-lived credentials)
- ✅ Automated Testing & Security Scanning
- ✅ Horizontal Pod Autoscaling
- ✅ Safe Rollout & Automated Rollback
- ✅ Comprehensive Observability

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Actions                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ PR Validation│  │ Build & Push │  │ Prod Deploy  │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │ OIDC Auth
                             ▼
          ┌─────────────────────────────────────┐
          │           AWS Cloud                 │
          │  ┌──────────┐      ┌─────────────┐ │
          │  │   ECR    │◄─────┤   EKS       │ │
          │  │ Registry │      │  Cluster    │ │
          │  └──────────┘      │             │ │
          │                    │ ┌─────────┐ │ │
          │                    │ │  Dev    │ │ │
          │                    │ │  Pods   │ │ │
          │                    │ └─────────┘ │ │
          │                    │ ┌─────────┐ │ │
          │                    │ │  Prod   │ │ │
          │                    │ │  Pods   │ │ │
          │                    │ └─────────┘ │ │
          │                    └─────────────┘ │
          └─────────────────────────────────────┘
```

---

## 📦 Prerequisites

- **AWS Account** with appropriate permissions
- **Terraform** v1.8.3+
- **kubectl** compatible with Kubernetes 1.28
- **Helm** v3.x
- **Docker** (for local testing)
- **AWS CLI** v2
- **GitHub Account** (for CI/CD)

---

## 🏗️ Phase 1: Infrastructure Setup

### 1️⃣ Set AWS Credentials

```bash
export AWS_ACCESS_KEY_ID=<your_access_key>
export AWS_SECRET_ACCESS_KEY=<your_secret_key>
export AWS_DEFAULT_REGION=<your_region>
```

Create an EC2 key pair if missing:

```bash
aws ec2 create-key-pair --key-name ahmedkey --query 'KeyMaterial' --output text > ahmedkey.pem
chmod 400 ahmedkey.pem
```

### 2️⃣ Initialize Terraform

```bash
terraform init
```

### 3️⃣ Plan Deployment

```bash
terraform plan
```

**Expected Resources:**
- VPC with DNS enabled
- Internet Gateway
- 2 Public subnets across availability zones
- EKS cluster (v1.28)
- Managed node group
- ECR repository
- IAM roles for GitHub Actions (OIDC)

### 4️⃣ Apply Deployment

```bash
terraform apply
```

### 5️⃣ Connect to the Cluster

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name ship-a-service

kubectl get nodes
```

**Expected Output:**

```
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-1-xxx.ec2.internal    Ready    <none>   5m    v1.28.x
ip-10-0-2-xxx.ec2.internal    Ready    <none>   5m    v1.28.x
```

### 📊 Infrastructure Outputs

| Output | Description |
|--------|-------------|
| `registry_url` | ECR URL for Docker images |
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | Kubernetes API endpoint |
| `cluster_certificate_authority_data` | Certificate for secure access |
| `kubeconfig_yaml` | Ready-to-use kubeconfig |
| `github_actions_role_arn` | IAM Role ARN for CI/CD |

---

## 🤖 Phase 2: CI Runner Configuration

### 1️⃣ SSH Key Setup

Generate SSH key pair:

```bash
ssh-keygen -t rsa -b 4096 -C "ansible" -f ~/.ssh/ansible_key
```

Copy public key to remote VM:

```bash
ssh-copy-id -i ~/.ssh/ansible_key.pub ansible@<VM_IP>
```

### 2️⃣ Update Ansible Inventory

Edit `inventories/inventory.ini`:

```ini
[ci_runner]
<VM_IP> ansible_user=ansible
```

### 3️⃣ Test Connection

```bash
ansible -i inventories/inventory.ini ci_runner -m ping
```

**Expected output:**

```
<VM_IP> | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 4️⃣ Run Setup Playbook

```bash
ansible-playbook -i inventories/dev/hosts.ini playbooks/setup_runner.yml --ask-become-pass
```

### ✅ What Gets Installed

- **System Prerequisites:** curl, unzip, ca-certificates
- **Docker:** CE, CLI, containerd, compose, buildx
- **Kubernetes CLI:** kubectl
- **Helm:** v3 for chart management
- **Terraform:** v1.8.3
- **AWS CLI:** v2
- **IAM Role Configuration:** OIDC-based authentication

---

## 🐹 Phase 3: Application

A minimal Go HTTP service with health endpoints and Prometheus metrics.

### Features

- **`/healthz`** → JSON health check with environment info
- **`/metrics`** → Prometheus-style request counter
- **`/`** → Hello endpoint (increments counter)
- Multi-stage Docker build
- Non-root user
- Built-in `HEALTHCHECK`
- Unit-test ready

### Docker Usage

#### Build Image

```bash
docker build -t app:local .
```

#### Run Container

```bash
docker run -d -p 8080:8080 --name app-test app:local
```

#### Test Health Endpoint

```bash
docker exec -it app-test wget -qO- http://localhost:8080/healthz
```

**Expected Output:**

```json
{
  "status": "ok",
  "SYS_ENV": "development"
}
```

#### Test Metrics

```bash
curl http://localhost:8080/metrics
```

**Expected Output:**

```
my_app_requests_total 42
```

---

## ⎈ Phase 4: Helm Chart

### 1️⃣ Chart Overview

**Location:** `charts/app/`

**Features:**
- Configurable replicas and resources
- Liveness and readiness probes
- Ingress + Service configuration
- Horizontal Pod Autoscaler (HPA)
- Rolling update strategy
- Automated rollback on failure

### 2️⃣ Directory Structure

```
charts/app/
├── Chart.yaml
├── values.dev.yaml
├── values.prod.yaml
├── templates/
│   ├── deployment.yaml   # Rolling update deployment
│   ├── service.yml       # ClusterIP service
│   ├── ingress.yml       # Ingress rules
│   ├── hpa.yaml          # Horizontal Pod Autoscaler
│   └── _helpers.tpl      # Template helpers
```

### 3️⃣ Deployment Features

#### Rolling Update Strategy

- Gradually replaces old pods
- Configurable limits:
  - `maxUnavailable: 1`
  - `maxSurge: 1`
- `--atomic` flag ensures automated rollback if health checks fail

#### Horizontal Pod Autoscaler

- Scales pods automatically based on CPU utilization
- Configurable min/max replicas
- Monitors `/metrics` endpoint for custom metrics

#### Probes & Health Checks

- **Liveness:** `/healthz` endpoint
- **Readiness:** `/healthz` endpoint
- `--wait` flag waits until all resources are ready

### 4️⃣ Deploy with Helm

**Development:**

```bash
helm upgrade --install ship-a-service charts/app/ \
  -f charts/app/values.dev.yaml \
  --atomic \
  --wait
```

**Production:**

```bash
helm upgrade --install ship-a-service charts/app/ \
  -f charts/app/values.prod.yaml \
  --atomic \
  --wait
```

---

## 🔄 Phase 5: CI/CD Pipelines

Three main workflows power the CI/CD pipeline:

### 1️⃣ PR Validation (`pr-validation.yml`)

**Trigger:** Pull Requests to `main` or manual dispatch

**Steps:**
- ✅ Lint & test Go application
- ✅ Docker build (no push) + Trivy security scan
- ✅ Terraform format/validate/plan
- ✅ Helm lint + chart unit tests
- ✅ IaC security scan (tfsec)

**Manual Trigger:** Available from GitHub Actions tab

### 2️⃣ Build & Push to Dev (`build-and-push.yml`)

**Trigger:** Merge/push to `main` or manual dispatch

**Steps:**
1. Build & push Docker image to ECR (`:main` + `:<short_sha>`)
2. Apply Terraform infrastructure
3. Deploy to Dev using Helm (`values.dev.yaml`)
4. Post-deploy smoke test (`/healthz`)
5. Generate deployment report

**Manual Trigger:** Available for testing or redeployment

### 3️⃣ Production Deployment (`Deploy_to_Production.yml`)

**Trigger:** Manual approval required

**Steps:**
1. Deploy to Production using Helm (`values.prod.yaml`)
2. Apply rollout strategy (rolling update with probes)
3. Automated rollback on failure
4. Upload SBOM and vulnerability scan reports
5. Publish deployment summary

**⚠️ Always manual** for controlled production deployment

### 🎯 Workflow Summary

| Workflow | Trigger | Purpose | Manual? |
|----------|---------|---------|---------|
| PR Validation | PRs to `main` | Quality gates | ✅ Yes |
| Build & Push | Merge to `main` | Dev deployment | ✅ Yes |
| Prod Deploy | Manual only | Production release | ✅ Required |

---

## 🔒 Phase 6: Security & Secrets

### OIDC-Based Authentication

- **No long-lived credentials** stored in GitHub
- CI pipelines authenticate to AWS using OpenID Connect (OIDC)
- Temporary credentials issued per workflow run

### Cloud-Native Secret Storage

- Sensitive data stored in **AWS SSM Parameter Store**
- Examples:
  - AWS Account ID
  - Database credentials
  - API keys

### Security Scanning

- **Trivy:** Container image vulnerability scanning
- **tfsec:** Terraform security analysis
- **SBOM Generation:** Software Bill of Materials for compliance

---

## 📊 Phase 7: Observability

### Application Metrics

#### `/metrics` Endpoint

Exposes Prometheus-compatible metrics:

```
my_app_requests_total 42
```

#### `/healthz` Endpoint

Returns app health and environment info:

```json
{
  "status": "ok",
  "SYS_ENV": "dev"
}
```

### Cloud Metrics

**CloudWatch Integration:**

- `cloudwatch-agent` → Cluster & pod metrics
- `aws-for-fluent-bit` → Pod logs to CloudWatch Logs

**Monitor CPU, memory, network, and logs:**

```bash
# View HPA status
kubectl get hpa

# Detailed HPA metrics
kubectl describe hpa ship-a-service-app-hpa

# Pod logs
kubectl logs -l app=ship-a-service --tail=100
```

### Key Metrics to Monitor

| Metric | Source | Purpose |
|--------|--------|---------|
| Request count | `/metrics` | Traffic patterns |
| Pod CPU/Memory | CloudWatch | Resource utilization |
| HPA scaling events | Kubernetes | Autoscaling behavior |
| Health check failures | `/healthz` | Service availability |

---

## 💰 Cost Management

### Cost Outputs

Terraform provides detailed cost estimates:

| Output | Description |
|--------|-------------|
| `monthly_cost_estimate` | Estimated monthly costs |
| `cost_report` | Formatted cost table with optimization tips |
| `total_monthly_cost` | Total monthly estimate |
| `total_daily_cost` | Daily breakdown |
| `total_hourly_cost` | Hourly breakdown |
| `budget_status` | OK, WARNING, or OVER BUDGET |
| `cost_comparison` | Compare minimal/dev/prod configurations |
| `cost_metadata` | Calculation method, source, date |

### Cost Components

- **EKS Control Plane:** ~$73/month
- **EC2 Node Group:** Based on instance type and count
- **ECR Storage:** Per GB stored
- **Data Transfer:** Egress charges
- **CloudWatch:** Logs and metrics

### Optimization Tips

1. Use spot instances for non-production workloads
2. Enable cluster autoscaler
3. Set appropriate HPA thresholds
4. Monitor ECR image lifecycle policies
5. Review CloudWatch log retention

---

## 🐛 Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
# Check pod status
kubectl get pods

# View pod events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
```

#### Health Check Failures

```bash
# Test health endpoint directly
kubectl exec -it <pod-name> -- wget -qO- http://localhost:8080/healthz
```

#### HPA Not Scaling

```bash
# Verify metrics server is running
kubectl get deployment metrics-server -n kube-system

# Check HPA status
kubectl describe hpa ship-a-service-app-hpa
```

#### Terraform Apply Failures

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check Terraform state
terraform show

# Force refresh
terraform refresh
```

#### GitHub Actions OIDC Issues

```bash
# Verify OIDC provider exists
aws iam list-open-id-connect-providers

# Check role trust policy
aws iam get-role --role-name <github-actions-role-name>
```
