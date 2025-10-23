Ship-a-Service: CI/CD Deployment & Management
1️⃣ Deployments
Development Environment

Deploy to Dev using CI/CD pipeline (build-and-push.yml) or manually:

cd charts/app
helm upgrade --install ship-a-service . \
  -f values.dev.yaml \
  --set image.repository=<ECR_URI> \
  --set image.tag=<IMAGE_TAG> \
  --namespace default \
  --create-namespace \
  --wait --atomic


--atomic: automatically rolls back if deployment fails.

--wait: waits until all pods are ready.

You can also trigger manually from the GitHub Actions “Actions” tab.

Production Environment

Deploy using Deploy_to_Production.yml:

cd charts/app
helm upgrade --install ship-a-service . \
  -f values.prod.yaml \
  --set image.repository=<ECR_URI> \
  --set image.tag=<IMAGE_TAG> \
  --namespace default \
  --wait --atomic


Rolling update strategy is applied.

/healthz endpoint is monitored; automatic rollback triggers on failure.

Manual approval is required in GitHub Actions workflow for production.

2️⃣ Rollbacks

Automated Helm Rollback

All deployments use --atomic:

- name: Helm deploy
  working-directory: charts/app
  run: |
    helm upgrade --install ship-a-service . \
      -f values.prod.yaml \
      --set image.repository=${{ env.IMAGE_URI }} \
      --set image.tag=${GITHUB_SHA::8} \
      --namespace default \
      --create-namespace \
      --wait \
      --atomic \
      --timeout 5m


--atomic: rollback automatically on failure.

--wait: ensures all pods are ready.

This pattern ensures safe deployments for Dev and Prod.

3️⃣ Troubleshooting & Observability
App Metrics & Health

Your Go app exposes two endpoints:

Health check: /healthz

{
  "status": "ok",
  "SYS_ENV": "dev"
}


Prometheus-style metrics: /metrics

my_app_requests_total 42


Check metrics & health:

kubectl port-forward svc/ship-a-service-app 8080:8080
curl http://localhost:8080/healthz
curl http://localhost:8080/metrics

Kubernetes HPA & Pod Health

List Horizontal Pod Autoscalers:

kubectl get hpa
kubectl describe hpa ship-a-service-app-hpa

4️⃣ Cleanup

Terraform Safe Destroy

Use safedestroy.sh for safer deletion:

cd infra/terraform
./safedestroy.sh
Deletes Helm releases and dependent resources in correct order.

Avoid destroying EKS first to prevent orphaned subnets/security groups.
