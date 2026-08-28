variable "name" {
  description = "Nome della User-Assigned Managed Identity."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group in cui creare l'identità."
  type        = string
}

variable "location" {
  description = "Regione Azure."
  type        = string
}

variable "tags" {
  description = "Tag da applicare alla risorsa."
  type        = map(string)
  default     = {}
}
