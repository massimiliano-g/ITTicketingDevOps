variable "unique_suffix" {
  description = "Suffisso alfanumerico minuscolo (senza trattini) per rendere globalmente unici i nomi di Key Vault e SQL Server."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.unique_suffix))
    error_message = "unique_suffix deve essere alfanumerico minuscolo, 3-10 caratteri, senza trattini o spazi."
  }
}

variable "aad_admin_login_name" {
  description = "UPN/email dell'utente Entra ID che sarà amministratore del server SQL di prod."
  type        = string
}

variable "aad_admin_object_id" {
  description = "Object ID (GUID) in Entra ID dell'amministratore SQL. Recuperabile con: az ad signed-in-user show --query id -o tsv"
  type        = string
}

variable "my_ip_address" {
  description = "Il tuo IP pubblico, per autorizzare connessioni dirette al database da locale. Lascia null per saltare la regola."
  type        = string
  default     = null
}

variable "image_tag" {
  description = "Tag delle immagini ticket-api/ticket-web da eseguire (build once, promote many: stessa immagine, tag diverso per promuoverla tra ambienti)."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Regione Azure."
  type        = string
  default     = "switzerlandnorth"
}

variable "tags" {
  description = "Tag comuni applicati alle risorse dell'ambiente prod."
  type        = map(string)
  default = {
    project     = "ticketsystem"
    environment = "prod"
    managed_by  = "terraform"
  }
}
