variable "name" {
  description = "Nome del Container Apps Environment."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group in cui creare l'environment."
  type        = string
}

variable "location" {
  description = "Regione Azure."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID ARM del Log Analytics Workspace (output 'id' del modulo log-analytics) a cui inviare i log dei container."
  type        = string
}

variable "tags" {
  description = "Tag da applicare alla risorsa."
  type        = map(string)
  default     = {}
}
