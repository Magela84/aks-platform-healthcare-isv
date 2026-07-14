# Architecture — PulseHealth AKS + Helm Platform

## 1. Design goals (from the client brief)

1. **Consolidate** 4 VM-hosted apps onto one managed Kubernetes platform.
2. **Tenant isolation** by namespace.
3. **Standardized packaging/release** for each app (Helm).
4. **Automatic scaling** during peak clinic hours.

## 2. Compute layout — two node pools

| Pool | Mode | Sizing | Runs |
|---|---|---|---|
| `system` | System | 1× `Standard_D2s_v3`, fixed | Cluster add-ons only (`only_critical_addons_enabled` taints it) |
| `user` | User | 1→4× `Standard_D2s_v3`, autoscaling | All patient workloads |

Separating the pools keeps CoreDNS/metrics-server/etc. off the same
nodes as tenant workloads, so an app spike can't starve the control
add-ons — and only the user pool pays for scale-out.

## 3. Two layers of autoscaling ("peak clinic hours")

- **Pods:** each app has a `HorizontalPodAutoscaler` (CPU + memory
  targets) — adds/removes pods as load changes.
- **Nodes:** the cluster autoscaler on the user pool adds/removes VMs
  when pods can't be scheduled / nodes go idle.

Both are required: pods scale in seconds, nodes back them in minutes.

## 4. Tenant isolation — three enforcing layers

1. **Namespace per app** — patient-portal / appointments / telehealth / billing.
2. **RBAC** — each team gets a namespace-scoped `Role` + `RoleBinding`
   (bound to the app ServiceAccount and the team's AAD group). No team
   can touch another tenant's namespace.
3. **NetworkPolicy (Calico)** — default-deny cross-tenant traffic; pods
   accept connections only from their own namespace and the ingress
   controller.

Pod Security Admission is set to `restricted` per namespace as a
healthcare-appropriate baseline.

## 5. Identity & secrets — nothing stored

- **ACR pulls:** the AKS **kubelet Managed Identity** is granted
  `AcrPull` via Terraform `azurerm_role_assignment`. No imagePullSecrets.
- **CI/CD:** GitHub Actions authenticates to Azure with **OIDC
  federated credentials** — no `AZURE_CLIENT_SECRET` in the repo.

## 6. Ingress & TLS

One shared **NGINX Ingress Controller** (single Azure load balancer)
fronts all four apps by hostname. **cert-manager** issues and renews
Let's Encrypt certs automatically from the `letsencrypt-prod`
ClusterIssuer referenced in each app's values.

## 7. Packaging — one chart, four releases

`helm/pulsehealth-app` is a single parameterized chart. Each app is a
separate Helm *release* driven by its file in `helm/values/`. Adding a
5th app = add a values file + a Dockerfile folder + a namespace/RBAC
entry. No new templates.

## 8. Observability

The OMS agent add-on streams container logs and cluster metrics to a
**Log Analytics workspace** (Container Insights), retention configurable
via `log_retention_days` (raise to 90+ for compliance).

## 9. What I'd add for production

- Remote Terraform state in Azure Storage (backend block ready in `providers.tf`).
- Azure Key Vault + CSI Secrets Store driver for app secrets.
- Private cluster + private ACR endpoint.
- Standard AKS SKU for the 99.95% uptime SLA.
- Azure Policy for AKS + image scanning (Defender for Containers).
