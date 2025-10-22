Security Overview – Ship-a-Service
1. IAM Roles & Policies

GitHub Actions Role

Created via OIDC; no long-lived keys stored in GitHub.

Least-privilege principle: only allows necessary actions:

Push/pull images in ECR.

Deploy and describe EKS cluster.

Read/write required SSM parameters.

Roles are scoped to resources, e.g., repo-specific ECR, cluster-limited access.

Node IAM Roles

Nodes have only permissions needed for workloads (e.g., read ConfigMaps, push logs).

2. Secrets & Sensitive Data

AWS Account ID and other sensitive info stored in SSM Parameter Store.

CI workflows fetch secrets at runtime; no secrets hardcoded in code or GitHub.

Rotation: periodic review + automatic regeneration of keys if used.

3. Supply-Chain Security

SBOM (Software Bill of Materials) generated for every build.

Image scanning: Trivy used to detect vulnerabilities (CRITICAL/HIGH fail pipeline).

IaC scanning: tfsec scans Terraform templates for security issues.

Provenance / Integrity: optional bonus: cosign can be used to sign images and verify authenticity.

4. Runtime Security

Pods run as non-root users.

Liveness/readiness probes prevent unhealthy pods from serving traffic.

Rolling updates with automated rollback ensure no broken deployment reaches production.

5. Observability for Security

CloudWatch monitors CPU, memory, and network.

Fluent Bit ships logs to CloudWatch Logs for audit and forensic needs.