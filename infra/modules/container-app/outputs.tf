output "id" {
  description = "Resource ID della Container App."
  value       = azurerm_container_app.this.id
}

output "fqdn" {
  description = "FQDN dell'ingress (pubblico se external_ingress = true, altrimenti *.internal.<default_domain> raggiungibile solo dentro il Container Apps Environment). Usa ingress[0].fqdn, non latest_revision_fqdn: quest'ultimo risulta vuoto per le app con ingress interno."
  value       = azurerm_container_app.this.ingress[0].fqdn
}
