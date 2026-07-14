#!/usr/bin/env bash
# ============================================================
# 01-deploy-infra.sh — provision AKS + ACR with Terraform
# ============================================================
# Run in Azure Cloud Shell from the repo root.
set -euo pipefail

echo "==> Terraform init/validate/plan/apply"
cd "$(dirname "$0")/../terraform"

# Uses terraform.tfvars (git-ignored) OR ARM_* env vars for auth.
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

echo ""
echo "==> Key outputs:"
terraform output
