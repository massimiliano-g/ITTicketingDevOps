variable "unique_suffix" {
  description = "Suffisso alfanumerico minuscolo (senza trattini) per rendere globalmente unici i nomi di Key Vault e SQL Server. Consigliato: lo stesso suffisso random a 6 caratteri usato per l'ambiente shared."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.unique_suffix))
    error_message = "unique_suffix deve essere alfanumerico minuscolo, 3-10 caratteri, senza trattini o spazi."
  }
}

variable "location" {
  description = "Regione Azure."
  type        = string
  default     = "switzerlandnorth"
}

variable "aad_admin_login_name" {
  description = "UPN/email dell'utente Entra ID che sarà amministratore del server SQL di dev (di norma la tua identità Azure)."
  type        = string
}

variable "aad_admin_object_id" {
  description = "Object ID (GUID) in Entra ID dell'amministratore SQL. Recuperabile con: az ad signed-in-user show --query id -o tsv"
  type        = string
}

variable "my_ip_address" {
  description = "Il tuo IP pubblico, per autorizzare connessioni dirette al database da locale (es. Azure Data Studio). Lascia null per saltare la regola. Verifica il tuo IP con: curl ifconfig.me"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tag comuni applicati alle risorse dell'ambiente dev."
  type        = map(string)
  default = {
    project     = "ticketsystem"
    environment = "dev"
    managed_by  = "terraform"
  }
}
