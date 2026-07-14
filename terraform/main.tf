# ============================================================
# main.tf — PulseHealth AKS + Helm Platform
# ============================================================
# BUILDS:
#   - Resource Group
#   - Log Analytics Workspace       (container + cluster logs)
#   - Azure Container Registry      (stores all 4 app images)
#   - AKS Cluster
#       * System node pool          (runs cluster add-ons only)
#       * User node pool            (runs the 4 patient apps, autoscaling)
#       * SystemAssigned identity   (no service principal secrets)
#       * Calico network policy     (namespace/tenant isolation)
#       * OMS agent -> Log Analytics
#   - RBAC: AcrPull for the cluster's kubelet identity
#           (lets nodes pull images from ACR with NO passwords)
#
# ZERO manual portal clicks — everything below is IaC.
# ============================================================

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    environment = var.environment
    project     = var.project
    client      = "PulseHealth Systems"
    managed_by  = "terraform"
    owner       = var.owner
  }
}

# ── Resource Group ───────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

# ── Log Analytics Workspace ──────────────────────────────────
# AKS sends container stdout/stderr and cluster metrics here via
# the OMS agent add-on. Also feeds Container Insights dashboards.

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

# ── Azure Container Registry ─────────────────────────────────
# One registry holds the images for all 4 patient apps:
#   patient-portal / appointments / telehealth / billing
# ACR name rules: 5-50 chars, lowercase alphanumeric, globally unique.

resource "azurerm_container_registry" "main" {
  name                = "acr${var.project}${var.environment}001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false # MI-only auth — no admin username/password
  tags                = local.common_tags
}

# ── AKS Cluster ──────────────────────────────────────────────
# default_node_pool = the SYSTEM pool. only_critical_addons_enabled
# taints it so ONLY cluster add-ons (CoreDNS, metrics-server, etc.)
# schedule here. All patient workloads land on the user pool below.

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = local.name_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.aks_sku_tier # Free (dev) or Standard (SLA-backed)
  tags                = local.common_tags

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    node_count                   = var.system_node_count
    os_disk_size_gb              = 30
    only_critical_addons_enabled = true # taint: keeps app pods off system nodes
    type                         = "VirtualMachineScaleSets"
    tags                         = local.common_tags
  }

  # Managed Identity — no service principal password stored anywhere.
  identity {
    type = "SystemAssigned"
  }

  # Calico gives us Kubernetes NetworkPolicy support, which is how we
  # enforce tenant isolation BETWEEN namespaces (default-deny + allow).
  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
  }

  # Stream logs + metrics to Log Analytics (Container Insights).
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  # Kubernetes RBAC on by default in provider v4 — every ServiceAccount
  # and Role in k8s/rbac/ is enforced by the API server.
}

# ── User Node Pool ───────────────────────────────────────────
# Where the 4 patient apps actually run. Autoscaling handles the
# "peak clinic hours" requirement at the NODE level; the per-app
# HorizontalPodAutoscalers handle it at the POD level.

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_vm_size
  mode                  = "User"
  os_disk_size_gb       = 30

  enable_auto_scaling = true
  min_count            = var.user_node_min
  max_count            = var.user_node_max

  tags = local.common_tags
}

# ── RBAC — AcrPull for the cluster ───────────────────────────
# Grants the kubelet (node) identity permission to pull images from
# ACR. This is the "ACR integration via Managed Identity" line in the
# brief — no imagePullSecrets, no passwords in any manifest.

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}
