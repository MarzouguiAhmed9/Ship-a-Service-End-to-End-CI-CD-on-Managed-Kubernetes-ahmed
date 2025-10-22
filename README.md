# Ship-a-Service: End-to-End CI/CD on Managed Kubernetes
Launch EKS Cluster with Terraform
1️⃣ Set AWS credentials
Export your AWS keys and region:
export AWS_ACCESS_KEY_ID=<your_access_key>
export AWS_SECRET_ACCESS_KEY=<your_secret_key>
export AWS_DEFAULT_REGION=<your_region>


Create key if missing:
aws ec2 create-key-pair --key-name ahmedkey --query 'KeyMaterial' --output text > ahmedkey.pem
chmod 400 ahmedkey.pem



3️⃣ Initialize Terraform
terraform init
4️⃣ Plan deployment
terraform plan
Check that Terraform plans to create your VPC, subnets, EKS cluster, node groups, and ECR repository.
5️⃣ Apply deployment
terraform apply

## 🎯 What's Been Built (Phase 1)

Infrastructure réseau

Crée un VPC avec DNS activé.

Ajoute une Internet Gateway pour le trafic sortant.

Définit une route publique (0.0.0.0/0).

Crée 2 subnets publics dans deux zones de disponibilité pour HA.

Associe les subnets à la route table.

EKS (Kubernetes)

Déploie un cluster EKS version 1.28.

Crée un managed node group avec un type d’instance, nombre min/max de nœuds, et SSH key.

Les nodes sont tagués et répartis sur les 2 subnets pour haute disponibilité.

ECR (Docker registry)

Crée un repository ECR ship-a-service avec scan d’image à la push et AES256 pour le stockage.

Politique de cycle de vie pour garder les 10 dernières images.

IAM & GitHub Actions (CI/CD)

Crée un OIDC provider pour GitHub Actions.

Crée un role IAM pour GitHub Actions avec permissions pour :

Pousser/puller les images dans ECR.

Déployer sur le cluster EKS (via une policy personnalisée).

## 🏗️ Architecture Diagram

```
# Ship-a-Service: End-to-End CI/CD on Managed Kubernetes

## 🏗️ Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                                    AWS Cloud                                         │
│                                                                                      │
│  ┌────────────────────────────────┐      ┌────────────────────────────────────────┐ │
│  │                                │      │                                        │ │
│  │      CI/CD Pipeline            │      │        VPC (10.0.0.0/16)              │ │
│  │                                │      │                                        │ │
│  │  ┌──────────────────────────┐  │      │  ┌───────────────────────────────────┐ │ │
│  │  │                          │  │      │  │      Internet Gateway            │ │ │
│  │  │  GitHub Repository       │  │      │  │      (Public Access)             │ │ │
│  │  │  MarzouguiAhmed9/        │  │      │  └─────────────┬─────────────────────┘ │ │
│  │  │  Ship-a-Service          │  │      │                │                       │ │
│  │  │                          │  │      │  ┌─────────────▼─────────────────────┐ │ │
│  │  └────────┬─────────────────┘  │      │  │    Public Route Table            │ │ │
│  │           │                    │      │  │    Route: 0.0.0.0/0 → IGW        │ │ │
│  │           │ Trigger            │      │  └──────┬──────────────────┬────────┘ │ │
│  │           │                    │      │         │                  │          │ │
│  │  ┌────────▼─────────────────┐  │      │  ┌──────▼────────┐  ┌─────▼────────┐ │ │
│  │  │                          │  │      │  │               │  │              │ │ │
│  │  │   GitHub Actions         │  │      │  │  Subnet A     │  │  Subnet B    │ │ │
│  │  │   Workflow               │  │      │  │  (us-east-1a) │  │  (us-east-1b)│ │ │
│  │  │                          │  │      │  │  10.0.1.0/24  │  │  10.0.2.0/24 │ │ │
│  │  │  1. Build & Test         │  │      │  │               │  │              │ │ │
│  │  │  2. Build Docker Image   │  │      │  │  ┌─────────┐  │  │  ┌─────────┐ │ │ │
│  │  │  3. Push to ECR          │  │      │  │  │  EKS    │  │  │  │  EKS    │ │ │
│  │  │  4. Deploy to EKS        │  │      │  │  │  Worker │  │  │  │  Worker │ │ │
│  │  │                          │  │      │  │  │  Nodes  │  │  │  │  Nodes  │ │ │
│  │  └────┬──────────────────┬──┘  │      │  │  │         │  │  │  │         │ │ │
│  │       │                  │     │      │  │  └────┬────┘  │  │  └────┬────┘ │ │
│  │       │ OIDC Auth        │     │      │  └───────┼───────┘  └───────┼──────┘ │ │
│  │       │                  │     │      │          │                  │        │ │
│  │  ┌────▼──────────────────▼───┐ │      │  ┌───────▼──────────────────▼──────┐ │ │
│  │  │                          │ │      │  │                                  │ │ │
│  │  │  GitHub OIDC Provider    │ │      │  │     EKS Control Plane            │ │ │
│  │  │  token.actions.          │ │      │  │     Kubernetes v1.28             │ │ │
│  │  │  githubusercontent.com    │ │      │  │                                  │ │ │
│  │  │                          │ │      │  │  - API Server                    │ │ │
│  │  │  Thumbprint:             │ │      │  │  - Scheduler                     │ │ │
│  │  │  6938fd4d98ba...         │ │      │  │  - Controller Manager            │ │ │
│  │  │                          │ │      │  │                                  │ │ │
│  │  └────────┬─────────────────┘ │      │  │  Tags:                           │ │ │
│  │           │                   │      │  │  kubernetes.io/cluster/shared    │ │ │
│  │           │ Assume Role       │      │  │  kubernetes.io/role/elb          │ │ │
│  │           │                   │      │  │                                  │ │ │
│  │  ┌────────▼─────────────────┐ │      │  └──────────────────────────────────┘ │ │
│  │  │                          │ │      │                                        │ │
│  │  │  IAM Role                │ │      └────────────────────────────────────────┘ │
│  │  │  github-actions-role     │ │                                                 │
│  │  │                          │ │                                                 │
│  │  │  Permissions:            │─┼─┐                                               │
│  │  │  ✓ ECR PowerUser         │ │ │                                               │
│  │  │  ✓ EKS Describe Cluster  │ │ │   ┌───────────────────────────────────────┐ │
│  │  │  ✓ EKS Access K8s API    │ │ │   │                                       │ │
│  │  │                          │ │ │   │   Amazon ECR Repository               │ │
│  │  │  Condition:              │ │ │   │   ship-a-service                      │ │
│  │  │  repo: MarzouguiAhmed9/  │ │ │   │                                       │ │
│  │  │  Ship-a-Service-...:*    │ │ │   │   Features:                           │ │
│  │  │                          │ │ └──▶│   🔒 AES256 Encryption                │ │
│  │  │  Tags:                   │ │     │   🔍 Scan on Push                     │ │
│  │  │  TTL: 7d                 │ │     │   ♻️  Lifecycle: Keep 10 images       │ │
│  │  │                          │ │     │   📦 Image Tag: MUTABLE               │ │
│  │  └──────────────────────────┘ │     │                                       │ │
│  │                                │     │   Latest Images:                      │ │
│  └────────────────────────────────┘     │   - ship-a-service:latest             │ │
│                                         │   - ship-a-service:v1.2.3             │ │
│                                         │   - ship-a-service:sha-abc123         │ │
│                                         │                                       │ │
│                                         └────────────┬──────────────────────────┘ │
│                                                      │                            │
│                                                      │ Pull Images                │
│                                                      │                            │
└──────────────────────────────────────────────────────┼────────────────────────────┘
                                                       │
                                                       │
                                   ┌───────────────────▼────────────────────┐
                                   │                                        │
                                   │     Application Containers             │
                                   │                                        │
                                   │  ┌──────────────┐  ┌──────────────┐   │
                                   │  │   Pod 1      │  │   Pod 2      │   │
                                   │  │   Subnet A   │  │   Subnet B   │   │
                                   │  │              │  │              │   │
                                   │  │   ┌──────┐   │  │   ┌──────┐   │   │
                                   │  │   │ App  │   │  │   │ App  │   │   │
                                   │  │   │      │   │  │   │      │   │   │
                                   │  │   └──────┘   │  │   └──────┘   │   │
                                   │  │              │  │              │   │
                                   │  └──────────────┘  └──────────────┘   │
                                   │                                        │
                                   │  Load Balanced across AZs              │
                                   │  Auto-scaling enabled                  │
                                   │                                        │
                                   └────────────────────────────────────────┘
                                                       │
                                                       │
                                                  ┌────▼─────┐
                                                  │          │
                                                  │  👥 Users│
                                                  │  (Public)│
                                                  │          │
                                                  └──────────┘
```

---



-

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




## 📊 Outputs

1️⃣ Infos techniques utiles pour déploiement

registry_url → URL du ECR pour push/pull les images Docker.

cluster_name → nom du cluster EKS.

cluster_endpoint → endpoint API du cluster pour kubectl.

cluster_certificate_authority_data → certificat pour sécuriser l’accès Kubernetes.

kubeconfig_yaml → fichier kubeconfig complet prêt à copier dans ~/.kube/config.

github_actions_role_arn → ARN du role IAM GitHub Actions pour CI/CD.

Ces outputs permettent à ton équipe ou à GitHub Actions d’interagir avec le cluster et le registry facilement.

2️⃣ Estimation et suivi des coûts

monthly_cost_estimate → détail complet par mois : coût control plane, nodes, ECR, logs, transfert de données, etc.

cost_report → version formatée et lisible (tableau avec conseils d’optimisation et budget).

total_monthly_cost, total_daily_cost, total_hourly_cost → résumé rapide.

budget_status → indique si tu es dans le budget (OK, WARNING, OVER BUDGET).

cost_comparison → comparaison entre différentes configurations (minimal/dev/prod).

cost_metadata → infos sur la méthode de calcul, source, date, etc.


## 📖 Next Steps

### Phase 2: Ansible (Planned)

This phase sets up the CI runner on a remote VM using Ansible.

1️⃣ Prérequis

Another VM available with IP address X

Main controller VM with Ansible installed

SSH access from controller to remote VM

2️⃣ Configure SSH Access
# Generate SSH key on main controller (if not already done)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Copy SSH public key to remote VM
ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@X

# Test SSH connection
ssh ansible@X


Replace X with the actual IP of your remote VM. You should be able to SSH without password after this step.

3️⃣ Update Ansible Inventory

Edit inventories/inventory.ini:

[ci_runner]
X ansible_user=ansible


Replace X with the IP of your remote VM.

4️⃣ Test Connection
ansible -i inventories/inventory.ini ci_runner -m ping


Expected output:

X | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

5️⃣ Run Setup Playbook
ansible-playbook -i inventories/dev/hosts.ini playbooks/setup_runner.yml --ask-become-pass


--ask-become-pass will prompt for sudo
✅ Quick Summary of the Playbook

System Prerequisites

Installs: curl, unzip, apt-transport-https, ca-certificates, software-properties-common

Docker

Installs Docker if not already installed

Packages: docker-ce, docker-ce-cli, containerd, docker-compose-plugin, docker-buildx-plugin

Kubernetes CLI (kubectl)

Downloads and installs kubectl to manage Kubernetes clusters

Helm

Installs Helm v3 for managing Kubernetes charts

Terraform

Downloads and installs Terraform v1.8.3

AWS CLI v2

Installs the AWS command-line tool

IAM Role via OIDC (GitHub Actions)

Configures the CI runner to assume an IAM role via GitHub OIDC

Exports AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN for CI jobs

Docker Handler

Restarts Docker if needed

### Phase 3: Application (Planned)
A minimal Go HTTP service exposing a health endpoint (/healthz) and metrics (/metrics). Container-ready with Docker multi-stage build, runs as non-root, includes HEALTHCHECK, and tracks request count.

Features

/healthz → Returns JSON with status and SYS_ENV environment variable.

/metrics → Prometheus-style counter: my_app_requests_total.

/ → Simple hello endpoint; increments request counter.

Docker multi-stage build.

Non-root user.
Unit-test ready for reliability.

Docker Usage
Build Image
docker build -t app:local .

Run Container
docker run -d -p 8080:8080 --name app-test app:local

Test Health Endpoint
docker exec -it app-test wget -qO- http://localhost:8080/healthz


Expected Output:

{
  "status": "ok",
  "SYS_ENV": "development" // or whatever SYS_ENV you set
}

### Phase 4: Helm Chart 


1️⃣ Helm Chart Overview

Location: charts/app/

Features:

Configurable replicas and resources

Liveness and readiness probes

Ingress (or Gateway) + Service

Horizontal Pod Autoscaler (HPA) based on CPU

Optional custom metrics or requests-per-second (RPS)

Safe rollout strategy (RollingUpdate)

Automated rollback on failed health checks

2️⃣ Directory Structure
charts/app/
├── Chart.yaml
├── values.dev.yaml
├── values.prod.yaml
├── templates/
│   ├── deployment.yaml   # Deployment with rolling update
│   ├── service.yml       # ClusterIP service
│   ├── ingress.yml       # Ingress rules
│   ├── hpa.yaml          # Horizontal Pod Autoscaler
│   └── _helpers.tpl      # Template helpers

3️⃣ Deployment Features
Rolling Update Strategy

Gradually replaces old pods

Configurable limits:

maxUnavailable (default: 1)

maxSurge (default: 1)

Safe rollout with --atomic ensures automated rollback if health checks fail

Horizontal Pod Autoscaler

Scales pods automatically based on CPU utilization

Configurable min/max replicas

Monitors /metrics endpoint for additional custom metrics if implemented

Probes & Health Checks

/healthz endpoint for liveness and readiness

--atomic: automatically rolls back if deployment fails

--wait: waits until all resources are ready before finishing====|used in ci workflow
### Phase 5: CI/CD 
GitHub Actions Pipelines

This project has three main workflows:

PR Validation (pr-validation.yml)

Triggered on Pull Requests to main or manually via GitHub.

Steps:

Lint & test Go app

Docker build (no push) + Trivy scan

Terraform fmt/validate/plan

Helm lint + chart unit tests

IaC security scan (tfsec)

Can be run manually from the Actions tab.

Build & Push to Dev / Dev Deploy (build-and-push.yml)

Triggered on merge/push to main or manually.

Steps:

Build & push Docker image to ECR (:main + :<short_sha>)

Terraform apply

Deploy to Dev using Helm (values.dev.yaml)

Post-deploy smoke test (/healthz)

Generate deployment report

Can be triggered manually for testing or redeployment.

Production Promotion (Deploy_to_Production.yml)

Manual approval required to run.

Steps:

Deploy to Production using Helm (values.prod.yaml)

Apply rollout strategy (rolling update with probes)

Automated rollback on failure

Upload SBOM and vulnerability scan reports

Publish deployment summary

Always run manually for controlled production deployment.

===|This clearly links workflow files to their purpose and highlights that all workflows can be triggered manually from GitHub Actions.

### Phase 6: CI/CD 
Secrets & IAM

OIDC-based authentication:
CI pipelines authenticate to AWS using OpenID Connect (OIDC). No long-lived credentials stored in GitHub.

Cloud-native secret storage:
Sensitive data like AWS Account ID is stored in AWS SSM Parameter Store.

### Phase 6: Observability

App metrics:

/metrics endpoint exposes a counter of total requests:

my_app_requests_total 42


/healthz endpoint shows app health and environment info:

{
  "status": "ok",
  "SYS_ENV": "dev"
}


Cloud metrics:

Use CloudWatch to monitor CPU, memory, network, and logs from all pods:

cloudwatch-agent → cluster & pod metrics

aws-for-fluent-bit → pod logs to CloudWatch Logs

Check HPA & app health:

kubectl get hpa
kubectl describe hpa ship-a-service-app-hpa


