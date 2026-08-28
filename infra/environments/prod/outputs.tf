output "resource_group_name" {
  description = "Nome del Resource Group di prod."
  value       = azurerm_resource_group.prod.name
}

output "resource_group_id" {
  description = "Resource ID del Resource Group di prod — usato come scope RBAC dall'identità CI/CD dedicata."
  value       = azurerm_resource_group.prod.id
}
