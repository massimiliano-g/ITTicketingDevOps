output "resource_group_name" {
  description = "Nome del Resource Group di dev."
  value       = azurerm_resource_group.dev.name
}

output "resource_group_id" {
  description = "Resource ID del Resource Group di dev — usato come scope RBAC dall'identità CI/CD dedicata."
  value       = azurerm_resource_group.dev.id
}

output "log_analytics_workspace_id" {
  description = "Resource ID del Log Analytics Workspace di dev."
  value       = module.log_analytics.id
}

output "key_vault_uri" {
  description = "URI del Key Vault di dev."
  value       = module.key_vault.uri
}

output "key_vault_name" {
  description = "Nome del Key Vault di dev."
  value       = module.key_vault.name
}

output "sql_server_fqdn" {
  description = "FQDN del SQL Server di dev, per la connection string dell'app."
  value       = module.sql_database.server_fqdn
}

output "sql_database_name" {
  description = "Nome del database di dev."
  value       = module.sql_database.database_name
}

output "container_apps_environment_id" {
  description = "Resource ID del Container Apps Environment di dev — servirà per creare la Container App ticket-api."
  value       = module.container_apps_environment.id
}

output "container_apps_environment_default_domain" {
  description = "Dominio di default dell'environment, prefisso degli URL pubblici delle future Container App."
  value       = module.container_apps_environment.default_domain
}

output "ticket_web_url" {
  description = "URL pubblico dell'interfaccia ticket-web."
  value       = "https://${module.ticket_web.fqdn}"
}

output "ticket_api_identity_name" {
  description = "Nome della User-Assigned Identity di ticket-api — è il nome da usare in 'CREATE USER [<questo>] FROM EXTERNAL PROVIDER' sul database (Entra ID risolve l'utenza per nome, non per principal_id)."
  value       = module.ticket_api_identity.name
}

output "ticket_api_identity_principal_id" {
  description = "Object ID della identità di ticket-api — solo per verifica/debug (es. controllare i role assignment con az cli)."
  value       = module.ticket_api_identity.principal_id
}
