variable "name" {
  description = "Nome del Log Analytics Workspace."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group in cui creare il workspace."
  type        = string
}

variable "location" {
  description = "Regione Azure."
  type        = string
}

variable "retention_in_days" {
  description = "Giorni di retention dei log. 30 è il minimo del piano PerGB2018 (oltre i 30gg si paga retention aggiuntiva)."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tag da applicare alla risorsa."
  type        = map(string)
  default     = {}
}
