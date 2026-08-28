output "resource_group_name" {
  description = "Nome del Resource Group di staging."
  value       = azurerm_resource_group.staging.name
}

output "resource_group_id" {
  description = "Resource ID del Resource Group di staging — usato come scope RBAC dall'identità CI/CD dedicata."
  value       = azurerm_resource_group.staging.id
}
