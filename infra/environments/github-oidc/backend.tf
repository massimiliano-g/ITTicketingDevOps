# ==============================================================================
# BACKEND REMOTO - AMBIENTE: GITHUB-OIDC
# ==============================================================================
# State separato per le identità CI/CD stesse — se mai andasse ricreato o
# distrutto, non deve toccare le risorse applicative di nessun ambiente, e
# viceversa un destroy di dev/staging/prod non deve mai poter cancellare le
# identità con cui GitHub Actions si autentica.
# ==============================================================================

terraform {
  required_version = ">= 1.9.0"

  backend "azurerm" {
    resource_group_name  = "rg-ticketsystem-tfstate"
    storage_account_name = "sttfstatetktj3acnr"
    container_name        = "tfstate"
    key                   = "github-oidc.terraform.tfstate"
    use_azuread_auth      = true
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
