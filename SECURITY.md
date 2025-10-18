SECURITY.md – Ship-a-Service
1. IAM Roles & Policies

Terraform Role: Used to create infrastructure (VPC, subnets, EKS, ECR).

CI/CD Role (GitLab Runner): Can push to ECR and deploy to EKS only.

Role uses OIDC, so GitLab can assume it temporarily.

2. Least-Privilege

CI/CD runner does not have full AWS access.

Only allows actions needed: push images, deploy apps.

Limits risk if credentials are leaked.

3. Secrets

No hard-coded AWS keys in GitLab.

Use OIDC or short-lived credentials.

Rotate roles/keys regularly.

4. Optional Security Checks

Sign images (Cosign) to ensure trust.

Scan images and Terraform code for vulnerabilities.