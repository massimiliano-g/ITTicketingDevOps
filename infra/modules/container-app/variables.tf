variable "name" {
  description = "Nome della Container App."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group in cui creare la Container App."
  type        = string
}

variable "location" {
  description = "Regione Azure."
  type        = string
}

variable "container_app_environment_id" {
  description = "Resource ID del Container Apps Environment in cui ospitare l'app."
  type        = string
}

variable "registry_server" {
  description = "Hostname dell'ACR da cui pullare l'immagine (es. acrticketsystemxxxxxx.azurecr.io)."
  type        = string
}

variable "identity_id" {
  description = "Resource ID di una User-Assigned Managed Identity (modulo managed-identity) già dotata del ruolo AcrPull sull'ACR — usata sia per il pull dell'immagine sia esposta al container applicativo."
  type        = string
}

variable "image" {
  description = "Immagine completa da eseguire (es. acrticketsystemxxxxxx.azurecr.io/ticket-api:dev)."
  type        = string
}

variable "target_port" {
  description = "Porta su cui il container ascolta (deve combaciare con ASPNETCORE_URLS nel Dockerfile)."
  type        = number
  default     = 8080
}

variable "external_ingress" {
  description = "true = raggiungibile da internet; false = raggiungibile solo da dentro il Container Apps Environment (comunicazione servizio-a-servizio)."
  type        = bool
  default     = false
}

variable "cpu" {
  description = "vCPU allocati al container (frazionabili)."
  type        = number
  default     = 0.25
}

variable "memory" {
  description = "Memoria allocata al container."
  type        = string
  default     = "0.5Gi"
}

variable "min_replicas" {
  description = "Repliche minime. 0 = scale-to-zero (nessun costo compute quando non c'è traffico, cold-start alla prima richiesta)."
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Repliche massime."
  type        = number
  default     = 1
}

variable "env_vars" {
  description = "Variabili d'ambiente del container (nome -> valore)."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tag da applicare alla risorsa."
  type        = map(string)
  default     = {}
}
