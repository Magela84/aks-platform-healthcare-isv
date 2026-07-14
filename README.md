# PulseHealth Systems — AKS + Helm Platform

> **Project 4 of the Magela84 Cloud Engineering Portfolio**
> Industry: Healthcare Technology · Client: PulseHealth Systems

Consolidate four patient-facing applications — running today on
individual, hand-patched VMs — onto a single **managed Azure Kubernetes
Service (AKS)** platform with tenant isolation, standardized Helm-based
releases, and automatic scaling for peak clinic hours.

Everything here is **Infrastructure as Code — zero manual portal clicks.**

---

## The client problem → what this solves

| PulseHealth pain point | Solution in this repo |
|---|---|
| 4 apps on separate VMs, inconsistent patching | One AKS cluster, one image build path |
| No tenant isolation | Namespace per app + NetworkPolicy + namespace-scoped RBAC |
| Ad-hoc, manual releases | One reusable Helm chart, per-app values files |
| Painful scaling during clinic peaks | HPA per app + cluster autoscaler on the user node pool |
| Passwords/keys sprawled across VMs | Managed Identity for ACR pulls, OIDC for CI — no stored secrets |

---

## Architecture

```
                    Internet (HTTPS)
                          │
              ┌───────────▼────────────┐
              │  NGINX Ingress + TLS   │  (cert-manager / Let's Encrypt)
              └───────────┬────────────┘
        ┌─────────────┬───┴────────┬──────────────┐
        ▼             ▼            ▼              ▼
 ┌────────────┐┌────────────┐┌────────────┐┌────────────┐
 │patient-    ││appointments││ telehealth ││  billing   │   namespaces
 │  portal    ││            ││            ││            │   (tenants)
 │ Deploy+HPA ││ Deploy+HPA ││ Deploy+HPA ││ Deploy+HPA │
 │ SA + RBAC  ││ SA + RBAC  ││ SA + RBAC  ││ SA + RBAC  │
 └────────────┘└────────────┘└────────────┘└────────────┘
        │  user node pool (autoscaling 1→4 nodes)         │
        └──────────────────────┬──────────────────────────┘
                               │ pulls images (Managed Identity, AcrPull)
                        ┌──────▼──────┐
                        │     ACR     │  acrpulsehealthdev001
                        └─────────────┘
   System node pool: cluster add-ons only (tainted)
   Observability: OMS agent → Log Analytics (Container Insights)
```

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full design and
[`docs/RUNBOOK.md`](docs/RUNBOOK.md) for step-by-step deploy commands.

---

## Repository layout

```
terraform/          AKS (system + user pools), ACR, Managed Identity, RBAC, Log Analytics
helm/pulsehealth-app/   ONE reusable chart: Deployment, Service, Ingress+TLS, HPA, ServiceAccount
helm/values/            per-app overrides (patient-portal, appointments, telehealth, billing)
k8s/namespaces.yaml     4 tenant namespaces (pod-security: restricted)
k8s/rbac/               per-team Role + RoleBinding + default-deny NetworkPolicy
k8s/ingress-nginx/      NGINX Ingress + cert-manager install notes
apps/                   4 placeholder Flask services + Dockerfiles (swap for real apps)
.github/workflows/      build → push to ACR (OIDC) → helm upgrade
scripts/                01 infra → 02 connect → 03 ingress → 04 deploy apps
```

---

## Quick start (Azure Cloud Shell)

```bash
git clone https://github.com/Magela84/pulsehealth-aks-helm-platform.git
cd pulsehealth-aks-helm-platform

# 1. Fill in your IDs (file is git-ignored)
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
#    edit subscription_id + tenant_id

# 2. Provision the platform
./scripts/01-deploy-infra.sh
./scripts/02-connect-cluster.sh
./scripts/03-install-ingress.sh

# 3. Deploy all four apps (pass your ACR login server)
./scripts/04-deploy-apps.sh acrpulsehealthdev001.azurecr.io
```

---

## Tech stack

Terraform · AKS · Helm · kubectl · Azure Container Registry · Managed
Identity · NGINX Ingress · cert-manager · GitHub Actions (OIDC) · Docker

## Cost note (dev sizing)

AKS control plane **Free** tier + 1 system node + 1–4 user nodes
(`Standard_D2s_v3`) + Basic ACR. Scale the node pool to zero-idle by
stopping the cluster (`az aks stop`) when not demoing to minimise spend.

---

*Built by [Magela84](https://github.com/Magela84) · Cloud Engineer @ Tek Tariq IT Solutions*
