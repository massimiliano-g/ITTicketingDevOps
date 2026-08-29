output "resource_group_name" {
  description = "Nome del Resource Group di prod."
  value       = azurerm_resource_group.prod.name
}

output "resource_group_id" {
  description = "Resource ID del Resource Group di prod — usato come scope RBAC dall'identità CI/CD dedicata."
  value       = azurerm_resource_group.prod.id
}

output "key_vault_uri" {
  description = "URI del Key Vault di prod."
  value       = module.key_vault.uri
}

output "sql_server_fqdn" {
  description = "FQDN del SQL Server di prod."
  value       = module.sql_database.server_fqdn
}

output "sql_database_name" {
  description = "Nome del database di prod."
  value       = module.sql_database.database_name
}

output "ticket_web_url" {
  description = "URL pubblico dell'interfaccia ticket-web di prod."
  value       = "https://${module.ticket_web.fqdn}"
}

output "ticket_api_identity_name" {
  description = "Nome della User-Assigned Identity di ticket-api — usato in 'CREATE USER [...] FROM EXTERNAL PROVIDER' sul database."
  value       = module.ticket_api_identity.name
}
