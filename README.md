Ship-a-Service: End-to-End CI/CD on Managed Kubernetes
Launch EKS Cluster with Terraform
1️⃣ Set AWS Credentials

Export your AWS keys and region:

export AWS_ACCESS_KEY_ID=<your_access_key>
export AWS_SECRET_ACCESS_KEY=<your_secret_key>
export AWS_DEFAULT_REGION=<your_region>


Create an EC2 key pair if missing:

aws ec2 create-key-pair --key-name ahmedkey --query 'KeyMaterial' --output text > ahmedkey.pem
chmod 400 ahmedkey.pem

2️⃣ Initialize Terraform
terraform init

3️⃣ Plan Deployment
terraform plan


Check that Terraform plans to create your VPC, subnets, EKS cluster, node groups, and ECR repository.

4️⃣ Apply Deployment
terraform apply

🎯 Phase 1: What’s Been Built

Network Infrastructure

Creates a VPC with DNS enabled.

Adds an Internet Gateway for outbound traffic.

Defines a public route (0.0.0.0/0).

Creates 2 public subnets in 2 availability zones for high availability.

Associates subnets with the route table.

EKS (Kubernetes)

Deploys an EKS cluster, version 1.28.

Creates a managed node group with instance type, min/max nodes, and SSH key.

Nodes are tagged and distributed across 2 subnets for high availability.

ECR (Docker Registry)

Creates an ECR repository ship-a-service with image scanning on push and AES256 encryption.

Lifecycle policy keeps the 10 most recent images.

IAM & GitHub Actions (CI/CD)

Creates an OIDC provider for GitHub Actions.

Creates an IAM role for GitHub Actions with permissions to:

Push/pull images in ECR.

Deploy to the EKS cluster (via a custom policy).

Connect to the Cluster
aws eks update-kubeconfig \
  --region us-east-1 \
  --name ship-a-service

kubectl get nodes


Expected Output:

NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-1-xxx.ec2.internal    Ready    <none>   5m    v1.28.x
ip-10-0-2-xxx.ec2.internal    Ready    <none>   5m    v1.28.x

📊 Outputs

Useful Technical Info

registry_url → ECR URL to push/pull Docker images

cluster_name → EKS cluster name

cluster_endpoint → API endpoint for kubectl

cluster_certificate_authority_data → certificate for secure access

kubeconfig_yaml → full kubeconfig file, ready to copy to ~/.kube/config

github_actions_role_arn → IAM Role ARN for GitHub Actions CI/CD

Cost Tracking

monthly_cost_estimate → estimated monthly costs (control plane, nodes, ECR, logs, bandwidth)

cost_report → formatted cost table with optimization tips

total_monthly_cost, total_daily_cost, total_hourly_cost → quick summary

budget_status → OK, WARNING, or OVER BUDGET

cost_comparison → compare minimal/dev/prod configurations

cost_metadata → info about calculation method, source, date
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
├── values.prod.yamlAKIAYS2NT2G72WXJLZUX

MaHgtw4li0ulPR2QisoEiCRq/vvAmyleDduZVbaK
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

### Phase 7: Observability

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


