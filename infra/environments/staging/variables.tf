variable "location" {
  description = "Regione Azure."
  type        = string
  default     = "switzerlandnorth"
}

variable "tags" {
  description = "Tag comuni applicati alle risorse dell'ambiente staging."
  type        = map(string)
  default = {
    project     = "ticketsystem"
    environment = "staging"
    managed_by  = "terraform"
  }
}
