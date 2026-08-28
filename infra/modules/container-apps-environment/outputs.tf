output "id" {
  description = "Resource ID dell'environment — servirà per creare le Container App al suo interno."
  value       = azurerm_container_app_environment.this.id
}

output "default_domain" {
  description = "Dominio di default assegnato all'environment (es. <hash>.<region>.azurecontainerapps.io), suffisso degli URL pubblici delle app ospitate."
  value       = azurerm_container_app_environment.this.default_domain
}

output "static_ip_address" {
  description = "IP statico in uscita dell'environment."
  value       = azurerm_container_app_environment.this.static_ip_address
}
