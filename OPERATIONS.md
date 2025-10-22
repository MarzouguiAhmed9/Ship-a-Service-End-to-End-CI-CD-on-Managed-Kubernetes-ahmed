
1️⃣ Deployments
Development Environment

Deploy to Dev using the CI/CD pipeline (build-and-push.yml) or manually:

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

Can also trigger manually from GitHub Actions Actions tab.

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

/healthz endpoint monitored; automatic rollback triggers if deployment fails.

Manual approval required in the GitHub Actions workflow for production.






2️⃣ Rollbacks
Helm Automated Rollback

All Helm deployments in this project use the --atomic flag, which automatically reverts the release if health checks fail. For example, in production:

# 🔟 Helm deploy with automated rollback
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


--atomic ensures automatic rollback on failure.

--wait waits until all pods are ready.

This pattern is applied in all workflows (Dev and Prod) for safe deployments.



3️⃣ Troubleshooting & Observability
App Metrics & Health

Your Go app exposes two key endpoints:

Health check: /healthz
Returns JSON with status and environment:

{
  "status": "ok",
  "SYS_ENV": "dev"
}


Prometheus-style metrics: /metrics
Tracks total requests:

my_app_requests_total 42


Check the metrics and health with:

kubectl port-forward svc/ship-a-service-app 8080:8080
curl http://localhost:8080/healthz
curl http://localhost:8080/metrics

Kubernetes HPA & Pod Health

List Horizontal Pod Autoscaler:

kubectl get hpa
kubectl describe hpa ship-a-service-app-hpa











4️⃣ Cleanup
Terraform Destroy (Safe)

Use your safedestroy.sh script for safer deletion:

cd infra/terraform
./safedestroy.sh


Ensures Helm releases and dependent resources are deleted in the correct order.

Avoid destroying EKS first to prevent orphaned subnets/security groups.