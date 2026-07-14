# ============================================================
# variables.tf — PulseHealth AKS + Helm Platform
# ============================================================

# ── Identity / subscription ──────────────────────────────────

variable "subscription_id" {
  description = "Azure Subscription ID. Set in terraform.tfvars (git-ignored) or ARM_SUBSCRIPTION_ID env var."
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID. Set in terraform.tfvars (git-ignored) or ARM_TENANT_ID env var."
  type        = string
}

# ── Naming / tagging ─────────────────────────────────────────

variable "project" {
  description = "Short project/client slug used in resource names and tags. Lowercase alphanumeric (feeds the ACR name)."
  type        = string
  default     = "pulsehealth"
}

variable "environment" {
  description = "Environment name — dev, staging, uat or prod."
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, uat, prod."
  }
}

variable "owner" {
  description = "Owner or team responsible for these resources (tag)."
  type        = string
  default     = "Magela84"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "East US"
}

# ── AKS control plane ────────────────────────────────────────

variable "kubernetes_version" {
  description = "Kubernetes version. Leave null to use the AKS default for the region. Check with: az aks get-versions -l eastus -o table"
  type        = string
  default     = null
}

variable "aks_sku_tier" {
  description = "AKS control-plane tier."
  type        = string
  default     = "Free"
  # Free     = no uptime SLA           — dev / learning
  # Standard = 99.95% SLA (~$73/month) — production
  validation {
    condition     = contains(["Free", "Standard"], var.aks_sku_tier)
    error_message = "aks_sku_tier must be Free or Standard."
  }
}

# ── System node pool (cluster add-ons only) ──────────────────

variable "system_node_vm_size" {
  description = "VM size for the system node pool."
  type        = string
  default     = "Standard_D2s_v3" # 2 vCPU, 8 GB — solid baseline for add-ons
}

variable "system_node_count" {
  description = "Fixed node count for the system pool."
  type        = number
  default     = 1
  # 1 is fine for dev. Use 2-3 for production HA of cluster add-ons.
}

# ── User node pool (patient workloads, autoscaling) ──────────

variable "user_node_vm_size" {
  description = "VM size for the user node pool that runs the apps."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "user_node_min" {
  description = "Minimum nodes in the autoscaling user pool."
  type        = number
  default     = 1
}

variable "user_node_max" {
  description = "Maximum nodes the user pool scales OUT to during peak clinic hours."
  type        = number
  default     = 4
}

# ── Container Registry ───────────────────────────────────────

variable "acr_sku" {
  description = "Azure Container Registry tier."
  type        = string
  default     = "Basic"
  # Basic    = ~$5/month   — dev
  # Standard = ~$20/month  — production
  # Premium  = ~$50/month  — geo-replication, private endpoints
}

# ── Logging ──────────────────────────────────────────────────

variable "log_retention_days" {
  description = "Log Analytics retention in days."
  type        = number
  default     = 30
  # Bump to 90+ for healthcare compliance retention requirements.
}
