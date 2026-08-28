output "resource_group_name" {
  description = "Nome del Resource Group condiviso."
  value       = azurerm_resource_group.shared.name
}

output "acr_id" {
  description = "Resource ID dell'ACR condiviso — servirà per assegnare i ruoli AcrPush (CI) e AcrPull (Container Apps / GitHub Actions) dagli altri ambienti."
  value       = module.container_registry.id
}

output "acr_login_server" {
  description = "Hostname dell'ACR condiviso, da usare come prefisso immagine (es. <login_server>/ticket-api:tag)."
  value       = module.container_registry.login_server
}

output "acr_name" {
  description = "Nome dell'ACR condiviso."
  value       = module.container_registry.name
}
