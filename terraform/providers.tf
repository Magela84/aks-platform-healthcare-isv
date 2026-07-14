# ============================================================
# providers.tf — PulseHealth AKS + Helm Platform
# ============================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-pulsehealth"
    storage_account_name = "sttfstatepulsehealth"
    container_name       = "tfstate"
    key                  = "pulsehealth.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
