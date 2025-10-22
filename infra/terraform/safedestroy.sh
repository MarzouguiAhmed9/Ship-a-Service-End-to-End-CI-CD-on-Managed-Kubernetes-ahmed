#!/bin/bash
# Safe destroy script for Terraform EKS infrastructure

set -e  # Stop on first error
echo "Starting safe destroy..."

# Make sure Terraform is initialized
terraform init

# Optional: show plan before destroying
terraform plan -destroy

# Ask for confirmation
read -p "Are you sure you want to destroy all resources? Type 'yes' to proceed: " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

# Destroy Terraform-managed resources
terraform destroy -auto-approve

echo "All resources destroyed safely."
