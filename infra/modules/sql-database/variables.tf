variable "server_name" {
  description = "Nome del logical SQL Server. Vincolo Azure: minuscolo, alfanumerico e trattini, globalmente unico."
  type        = string
}

variable "database_name" {
  description = "Nome del database (unico solo all'interno del server, non globalmente)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group in cui creare server e database."
  type        = string
}

variable "location" {
  description = "Regione Azure."
  type        = string
}

variable "aad_admin_login_name" {
  description = "UPN/nome visualizzato dell'utente o gruppo Entra ID che sarà amministratore del server SQL (es. la tua email di login Azure)."
  type        = string
}

variable "aad_admin_object_id" {
  description = "Object ID (GUID) in Entra ID dell'utente/gruppo amministratore. Recuperabile con: az ad signed-in-user show --query id -o tsv"
  type        = string
}

variable "my_ip_address" {
  description = "IP pubblico da autorizzare sul firewall del server per connessioni dirette (es. da SSMS/Azure Data Studio in locale). null per non aggiungere la regola."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "SKU serverless General Purpose (formato GP_S_Gen5_<vCore>). GP_S_Gen5_1 = 1 vCore, il minimo disponibile."
  type        = string
  default     = "GP_S_Gen5_1"
}

variable "max_size_gb" {
  description = "Dimensione massima del database in GB."
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "vCore minimi a cui il database scala quando attivo (frazionabile solo nel piano serverless)."
  type        = number
  default     = 0.5
}

variable "auto_pause_delay_in_minutes" {
  description = "Minuti di inattività dopo i quali il database va in pausa (compute a costo zero). 60 è il default consigliato per un progetto di test."
  type        = number
  default     = 60
}

variable "tags" {
  description = "Tag da applicare alle risorse."
  type        = map(string)
  default     = {}
}
