Tutorial: Automating Deployment of a Web Service on EKS
Overview

This tutorial shows how to deploy and integrate a web service on a managed Kubernetes cluster (EKS) using Terraform, Helm, and GitHub Actions.

Features included:

CI/CD pipelines (PR validation, dev deploy, production promotion)

Infrastructure provisioning with Terraform

Dockerized Go web service with health and metrics endpoints

Helm chart deployment with HPA and safe rollout

Observability via CloudWatch

1️⃣ Setup Infrastructure

Set AWS credentials

export AWS_ACCESS_KEY_ID=<your_access_key>
export AWS_SECRET_ACCESS_KEY=<your_secret_key>
export AWS_DEFAULT_REGION=<your_region>


Create SSH key if needed

aws ec2 create-key-pair --key-name ahmedkey --query 'KeyMaterial' --output text > ahmedkey.pem
chmod 400 ahmedkey.pem


Initialize Terraform

terraform init
terraform plan
terraform apply


This deploys:

VPC, subnets, IGW

EKS cluster + managed node group

ECR repository

IAM roles for GitHub Actions

2️⃣ Build & Run App Locally

Build Docker image

docker build -t app:local ./app/src


Run container

docker run -d -p 8080:8080 --name app-test app:local


Test endpoints

curl http://localhost:8080/healthz
curl http://localhost:8080/metrics


/healthz → app status + SYS_ENV

/metrics → request counter

3️⃣ Helm Deployment

Deploy to dev

helm upgrade --install ship-a-service ./charts/app \
  -f values.dev.yaml \
  --set image.repository=$IMAGE_URI \
  --set image.tag=<short_sha> \
  --namespace default \
  --create-namespace \
  --wait \
  --atomic \
  --timeout 5m


Check HPA & Pods

kubectl get hpa
kubectl describe hpa ship-a-service-app-hpa
kubectl get pods -n default -l app=app


Rollback if needed

helm rollback ship-a-service <revision>

4️⃣ CI/CD Pipelines

PR Validation: pr-validation.yml
Lint, test, docker build (no push), Trivy scan, Terraform validate, Helm lint & tests, tfsec scan.

Build & Push / Dev Deploy: build-and-push.yml
Build & push Docker images, Terraform apply, Helm deploy to dev, smoke test.

Production Promotion: Deploy_to_Production.yml
Manual approval, Helm deploy to prod, automated rollback on failure.

All workflows can be run manually from GitHub Actions.

5️⃣ Observability

Metrics: /metrics endpoint (request counter my_app_requests_total)

Health: /healthz endpoint

CloudWatch:

cloudwatch-agent → CPU, memory, network metrics

aws-for-fluent-bit → pod logs

6️⃣ Cleanup
# Destroy resources safely
./safedestroy.sh
terraform destroy


Note: Ensure Helm releases are deleted and AWS resources are cleaned in proper order.