variable "name" {
  description = "Nome del Key Vault. Vincolo Azure: 3-24 caratteri, alfanumerico e trattini, globalmente unico."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group in cui creare il Key Vault."
  type        = string
}

variable "location" {
  description = "Regione Azure."
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID di Entra ID (di norma data.azurerm_client_config.current.tenant_id)."
  type        = string
}

variable "tags" {
  description = "Tag da applicare alla risorsa."
  type        = map(string)
  default     = {}
}
