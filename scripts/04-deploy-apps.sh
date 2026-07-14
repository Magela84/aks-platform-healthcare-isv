#!/usr/bin/env bash
# ============================================================
# 04-deploy-apps.sh — namespaces + RBAC + all 4 Helm releases
# ============================================================
# Assumes images are already in ACR (pipeline or `az acr build`).
set -euo pipefail
cd "$(dirname "$0")/.."

# Pass your ACR login server as arg 1, e.g.:
#   ./scripts/04-deploy-apps.sh acrpulsehealthdev001.azurecr.io
ACR_LOGIN_SERVER="${1:?Usage: 04-deploy-apps.sh <acr-login-server>}"
APPS=(patient-portal appointments telehealth billing)

echo "==> Creating namespaces"
kubectl apply -f k8s/namespaces.yaml

echo "==> Applying per-namespace RBAC + NetworkPolicies"
kubectl apply -f k8s/rbac/

for app in "${APPS[@]}"; do
  echo "==> Deploying $app"
  helm upgrade --install "$app" ./helm/pulsehealth-app \
    --namespace "$app" \
    --values "helm/values/${app}.values.yaml" \
    --set image.repository="${ACR_LOGIN_SERVER}/${app}" \
    --set image.tag=latest \
    --wait --timeout 5m
done

echo ""
echo "==> All releases:"
helm list --all-namespaces
