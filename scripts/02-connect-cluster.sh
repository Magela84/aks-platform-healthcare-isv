#!/usr/bin/env bash
# ============================================================
# 02-connect-cluster.sh — point kubectl at the new AKS cluster
# ============================================================
set -euo pipefail
cd "$(dirname "$0")/../terraform"

RG=$(terraform output -raw resource_group_name)
AKS=$(terraform output -raw aks_cluster_name)

echo "==> Getting credentials for $AKS in $RG"
az aks get-credentials --resource-group "$RG" --name "$AKS" --overwrite-existing

echo "==> Cluster nodes:"
kubectl get nodes -o wide
