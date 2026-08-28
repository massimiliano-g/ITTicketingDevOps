variable "unique_suffix" {
  description = "Suffisso alfanumerico minuscolo (senza trattini) usato per rendere globalmente unico il nome dell'ACR. Consigliato: lo stesso generato/usato dallo script di bootstrap per lo storage account, per coerenza tra le risorse del progetto."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.unique_suffix))
    error_message = "unique_suffix deve essere alfanumerico minuscolo, 3-10 caratteri, senza trattini o spazi."
  }
}

variable "location" {
  description = "Regione Azure in cui creare le risorse condivise."
  type        = string
  default     = "switzerlandnorth"
}

variable "tags" {
  description = "Tag comuni applicati alle risorse condivise."
  type        = map(string)
  default = {
    project     = "ticketsystem"
    environment = "shared"
    managed_by  = "terraform"
  }
}
