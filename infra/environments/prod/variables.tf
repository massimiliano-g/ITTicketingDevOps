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
