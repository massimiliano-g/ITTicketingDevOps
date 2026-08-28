# ==============================================================================
# AMBIENTE: prod
# ==============================================================================
# Solo il Resource Group per ora — un contenitore stabile a cui agganciare
# l'RBAC dell'identità CI/CD di prod (infra/environments/github-oidc) prima
# ancora che le risorse applicative di questo ambiente vengano definite.
# ==============================================================================

resource "azurerm_resource_group" "prod" {
  name     = "rg-ticketsystem-prod"
  location = var.location
  tags     = var.tags
}
