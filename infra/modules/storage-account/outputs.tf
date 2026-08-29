output "id" {
  description = "Resource ID dello storage account — usato come scope per il ruolo RBAC Storage Blob Data Contributor."
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "Nome dello storage account."
  value       = azurerm_storage_account.this.name
}

output "container_uri" {
  description = "URI HTTPS del container — usato dalla Container App come Storage:ContainerUri (letto con Managed Identity, nessuna chiave)."
  value       = "https://${azurerm_storage_account.this.name}.blob.core.windows.net/${azurerm_storage_container.this.name}"
}
