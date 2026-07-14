# ============================================================
# providers.tf — PulseHealth AKS + Helm Platform
# ============================================================
# Declares the Terraform version, the AzureRM provider, and
# (optionally) a remote state backend.
#
# WHY THIS FILE:
#   Keeping provider + backend config separate from main.tf is
#   the same pattern used in Projects 1-3. It makes the infra
#   files easier to read and lets you swap backends per project.
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # ── Remote state (recommended once this leaves your machine) ──
  # Store state in an Azure Storage Account so Cloud Shell and
  # GitHub Actions share the SAME state. Create the storage first
  # (one-time), then uncomment and run: terraform init -migrate-state
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstatepulsehealth"   # must be globally unique
  #   container_name       = "tfstate"
  #   key                  = "pulsehealth-aks.tfstate"
  # }
}

provider "azurerm" {
  features {}

  # subscription_id / tenant_id come from variables so NO real IDs
  # ever get committed. Set them in terraform.tfvars (git-ignored)
  # or via env vars ARM_SUBSCRIPTION_ID / ARM_TENANT_ID in Cloud Shell.
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
