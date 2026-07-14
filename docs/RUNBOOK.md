# Runbook — Deploy PulseHealth AKS + Helm Platform

Step-by-step commands. Run from **Azure Cloud Shell** (has az, kubectl,
helm, terraform pre-installed) after `git clone`.

---

## 0. Prerequisites

```bash
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
az account show -o table

# Register providers once per subscription
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.OperationsManagement
```

Fill in your IDs (git-ignored file):

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# edit subscription_id and tenant_id
```

---

## 1. Provision infrastructure (Terraform)

```bash
./scripts/01-deploy-infra.sh
```

This creates: resource group, Log Analytics, ACR, AKS (system + user
pools), and the AcrPull role assignment. Takes ~8–12 minutes.

Grab the outputs you'll reuse:

```bash
cd terraform
terraform output acr_login_server        # e.g. acrpulsehealthdev001.azurecr.io
terraform output get_credentials_command
cd ..
```

---

## 2. Connect kubectl

```bash
./scripts/02-connect-cluster.sh
kubectl get nodes -o wide     # expect system + user nodes Ready
```

---

## 3. Install NGINX Ingress + cert-manager

```bash
./scripts/03-install-ingress.sh
```

Note the **EXTERNAL-IP** of `ingress-nginx-controller`, then point your
app DNS records (or `/etc/hosts` for a demo) at it. Apply the
ClusterIssuer from `k8s/ingress-nginx/README.md`.

---

## 4. Build images + deploy the four apps

Build images straight in ACR (no local Docker):

```bash
ACR=$(cd terraform && terraform output -raw acr_name)
for app in patient-portal appointments telehealth billing; do
  az acr build --registry "$ACR" --image "$app:latest" "apps/$app"
done
```

Deploy namespaces, RBAC and all releases:

```bash
LOGIN=$(cd terraform && terraform output -raw acr_login_server)
./scripts/04-deploy-apps.sh "$LOGIN"
```

Verify:

```bash
kubectl get pods,hpa,ingress --all-namespaces
helm list --all-namespaces
```

---

## 5. CI/CD (GitHub Actions, OIDC) — one-time setup

Create a workload-identity app + federated credential so Actions can
deploy without a stored secret:

```bash
APP_ID=$(az ad app create --display-name "gh-pulsehealth-deploy" --query appId -o tsv)
az ad sp create --id "$APP_ID"

# Federate to your repo's main branch
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "gh-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:Magela84/pulsehealth-aks-helm-platform:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Grant it AcrPush + AKS admin (scope to the RG for least privilege in prod)
SUB=$(az account show --query id -o tsv)
az role assignment create --assignee "$APP_ID" --role "AcrPush" \
  --scope "/subscriptions/$SUB/resourceGroups/rg-pulsehealth-dev"
az role assignment create --assignee "$APP_ID" --role "Azure Kubernetes Service Cluster User Role" \
  --scope "/subscriptions/$SUB/resourceGroups/rg-pulsehealth-dev"
```

Then in the GitHub repo → Settings:

- **Secrets:** `AZURE_CLIENT_ID` (=`$APP_ID`), `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- **Variables:** `ACR_NAME`, `RESOURCE_GROUP`, `AKS_CLUSTER`

Trigger a deploy: Actions tab → *Build and Deploy PulseHealth App* →
Run workflow → pick the app.

---

## 6. Teardown (stop the meter)

```bash
# Pause compute but keep everything:
az aks stop --resource-group rg-pulsehealth-dev --name aks-pulsehealth-dev

# Or destroy it all:
cd terraform && terraform destroy
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Pods `ImagePullBackOff` | Confirm AcrPull role assignment applied; image tag exists in ACR |
| HPA shows `<unknown>` targets | metrics-server needs resource *requests* set (they are, in values) |
| Ingress has no external IP | Wait 2–3 min; check `kubectl get events -n ingress-nginx` |
| Cert stuck `pending` | DNS must resolve to ingress IP before Let's Encrypt HTTP-01 works |
| `terraform apply` auth error | `az login` in Cloud Shell + correct subscription/tenant in tfvars |
