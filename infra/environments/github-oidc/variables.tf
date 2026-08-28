variable "github_subject_prefix" {
  description = "Prefisso immutabile del subject claim OIDC (formato 'owner@owner-id/repo@repo-id'), visibile in Settings -> Actions -> General -> OIDC del repository ('Default subject claim prefix'). GitHub usa questo formato con ID numerici — non solo i nomi — per i repository creati dopo il 15 luglio 2026, per evitare ambiguità se il repo viene rinominato/trasferito in futuro."
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
