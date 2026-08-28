output "id" {
  description = "Resource ID dell'identità — da passare al blocco identity/registry di una Container App."
  value       = azurerm_user_assigned_identity.this.id
}

output "principal_id" {
  description = "Object ID dell'identità in Entra ID — per assegnare ruoli RBAC (es. AcrPull)."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Application (client) ID — necessario nella connection string SQL (Authentication=Active Directory Managed Identity;User Id=<client_id>) quando si usa una User-Assigned Identity."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "name" {
  description = "Nome dell'identità — deve combaciare col nome usato in 'CREATE USER [...] FROM EXTERNAL PROVIDER' su SQL."
  value       = azurerm_user_assigned_identity.this.name
}
