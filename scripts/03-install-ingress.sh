#!/usr/bin/env bash
# ============================================================
# 03-install-ingress.sh — NGINX Ingress + cert-manager
# ============================================================
set -euo pipefail

echo "==> Installing NGINX Ingress Controller"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.replicaCount=2

echo "==> Installing cert-manager"
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true

echo "==> Waiting for ingress external IP (Ctrl-C once it appears)..."
kubectl get svc -n ingress-nginx ingress-nginx-controller -w
