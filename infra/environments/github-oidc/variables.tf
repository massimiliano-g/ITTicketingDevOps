variable "github_repository" {
  description = "Repository GitHub nel formato 'owner/repo' (es. massimiliano-g/ITTicketingDevOps) — usato per costruire i subject claim delle Federated Identity Credential."
  type        = string
}

variable "location" {
  description = "Regione Azure."
  type        = string
  default     = "switzerlandnorth"
}

variable "tags" {
  description = "Tag comuni applicati alle risorse CI/CD."
  type        = map(string)
  default = {
    project     = "ticketsystem"
    purpose     = "github-actions-oidc"
    managed_by  = "terraform"
  }
}
