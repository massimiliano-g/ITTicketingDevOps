output "id" {
  description = "Resource ID dell'ACR (serve per assegnare ruoli RBAC AcrPush/AcrPull)."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Nome dell'ACR."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Hostname dell'ACR (es. acrticketsystemxyz.azurecr.io) usato per docker push/pull e come riferimento immagine nei Container Apps."
  value       = azurerm_container_registry.this.login_server
}
