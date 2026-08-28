output "dev_client_id" {
  description = "Client ID dell'identità CI/CD di dev — da salvare come variabile/secret GitHub (AZURE_CLIENT_ID_DEV)."
  value       = azurerm_user_assigned_identity.dev.client_id
}

output "staging_client_id" {
  description = "Client ID dell'identità CI/CD di staging — da salvare come variabile/secret GitHub (AZURE_CLIENT_ID_STAGING)."
  value       = azurerm_user_assigned_identity.staging.client_id
}

output "prod_client_id" {
  description = "Client ID dell'identità CI/CD di prod — da salvare come variabile/secret GitHub (AZURE_CLIENT_ID_PROD)."
  value       = azurerm_user_assigned_identity.prod.client_id
}

output "tenant_id" {
  description = "Tenant ID — uguale per tutte e tre le identità, da salvare come AZURE_TENANT_ID."
  value       = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  description = "Subscription ID — da salvare come AZURE_SUBSCRIPTION_ID."
  value       = data.azurerm_client_config.current.subscription_id
}
