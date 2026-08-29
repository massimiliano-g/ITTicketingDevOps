variable "name" {
  description = "Nome dello storage account. Vincolo Azure: 3-24 caratteri, minuscolo, solo alfanumerico (niente trattini), globalmente unico."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group in cui creare lo storage account."
  type        = string
}

variable "location" {
  description = "Regione Azure."
  type        = string
}

variable "container_name" {
  description = "Nome del blob container."
  type        = string
  default     = "attachments"
}

variable "tags" {
  description = "Tag da applicare alle risorse."
  type        = map(string)
  default     = {}
}
