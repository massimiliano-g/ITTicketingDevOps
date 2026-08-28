variable "name" {
  description = "Nome dell'Azure Container Registry. Deve essere alfanumerico, globalmente unico, 5-50 caratteri (niente trattini)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group in cui creare l'ACR."
  type        = string
}

variable "location" {
  description = "Regione Azure."
  type        = string
}

variable "sku" {
  description = "SKU dell'ACR: Basic, Standard o Premium."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku deve essere uno tra: Basic, Standard, Premium."
  }
}

variable "tags" {
  description = "Tag da applicare alla risorsa."
  type        = map(string)
  default     = {}
}
