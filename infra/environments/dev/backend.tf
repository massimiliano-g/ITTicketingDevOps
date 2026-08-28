# ==============================================================================
# BACKEND REMOTO - AMBIENTE: DEV
# ==============================================================================
# Ogni ambiente ha il proprio state file (parametro "key"), ma condivide lo
# stesso storage account/container creati dallo script di bootstrap.
#
# RILEVANZA AZ-305: isolare gli state per ambiente è ciò che evita che un
# errore in dev (es. un "terraform destroy" lanciato per sbaglio) possa
# toccare le risorse di staging o prod — è lo stesso principio del
# "blast radius" che l'esame applica a subscription/management group design.
# ==============================================================================

terraform {
  required_version = ">= 1.9.0"

  backend "azurerm" {
    resource_group_name = "rg-ticketsystem-tfstate"
    storage_account_name = "sttfstatetktj3acnr" # output dello script di bootstrap
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
    use_azuread_auth     = true # autenticazione via Azure AD, non Storage Account Key
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
