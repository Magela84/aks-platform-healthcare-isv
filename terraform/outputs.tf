# ============================================================
# outputs.tf — PulseHealth AKS + Helm Platform
# ============================================================

output "resource_group_name" {
  description = "Resource group holding all PulseHealth resources."
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "AKS cluster name — use with: az aks get-credentials"
  value       = azurerm_kubernetes_cluster.main.name
}

output "get_credentials_command" {
  description = "Copy/paste this to point kubectl at the new cluster."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name} --overwrite-existing"
}

output "aks_kubelet_identity_object_id" {
  description = "Object ID of the kubelet (node) identity granted AcrPull."
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "acr_name" {
  description = "Azure Container Registry name."
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "ACR login server — prefix your image tags with this."
  value       = azurerm_container_registry.main.login_server
  # Example: acrpulsehealthdev001.azurecr.io
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace feeding Container Insights."
  value       = azurerm_log_analytics_workspace.main.id
}

output "node_resource_group" {
  description = "Auto-created MC_ resource group that holds the node VMSS, load balancer and public IPs."
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}
