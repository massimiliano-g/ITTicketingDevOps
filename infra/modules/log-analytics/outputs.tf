output "id" {
  description = "Resource ID ARM del workspace — è quello che l'argomento log_analytics_workspace_id di azurerm_container_app_environment si aspetta."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_id" {
  description = "Workspace/Customer ID (GUID) — usato per query dirette via API/CLI, non serve al Container Apps Environment."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "primary_shared_key" {
  description = "Chiave primaria del workspace, per agent/integrazioni che la richiedono esplicitamente."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}
