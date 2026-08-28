# ==============================================================================
# AMBIENTE: staging
# ==============================================================================
# Solo il Resource Group per ora — un contenitore stabile a cui agganciare
# l'RBAC dell'identità CI/CD di staging (infra/environments/github-oidc)
# prima ancora che le risorse applicative di questo ambiente vengano
# definite. Il resto (Log Analytics, Key Vault, SQL, Container Apps) verrà
# aggiunto seguendo lo stesso schema già usato per dev.
# ==============================================================================

resource "azurerm_resource_group" "staging" {
  name     = "rg-ticketsystem-staging"
  location = var.location
  tags     = var.tags
}
