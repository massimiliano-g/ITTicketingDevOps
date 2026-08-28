output "id" {
  description = "Resource ID del Key Vault — necessario per assegnare ruoli RBAC (es. Key Vault Secrets Officer/User)."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Nome del Key Vault."
  value       = azurerm_key_vault.this.name
}

output "uri" {
  description = "URI del Key Vault (es. https://kv-tkt-dev-xxxxxx.vault.azure.net/), usato dall'app/SDK per leggere i secret."
  value       = azurerm_key_vault.this.vault_uri
}
