output "server_id" {
  description = "Resource ID del logical SQL Server."
  value       = azurerm_mssql_server.this.id
}

output "server_fqdn" {
  description = "FQDN del server (es. sql-tkt-dev-xxxxxx.database.windows.net), da usare nella connection string dell'app."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "database_id" {
  description = "Resource ID del database."
  value       = azurerm_mssql_database.this.id
}

output "database_name" {
  description = "Nome del database."
  value       = azurerm_mssql_database.this.name
}
