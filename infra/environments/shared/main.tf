# ==============================================================================
# AMBIENTE: shared
# ==============================================================================
# Contiene le risorse condivise tra dev/staging/prod: al momento solo il
# Resource Group dedicato e l'Azure Container Registry (pattern "build once,
# promote many" — vedi commento nel modulo container-registry).
#
# Perché un Resource Group separato per "shared": un RG è anche il confine
# naturale per RBAC/policy/lifecycle in Azure. Le risorse condivise hanno un
# lifecycle indipendente da ogni singolo ambiente (un "terraform destroy" su
# dev non deve mai poter toccare l'ACR usato anche da staging/prod).
#
# RILEVANZA AZ-305: il Resource Group come unità di scoping per RBAC/Azure
# Policy/lifecycle è un concetto cardine di "Design governance" nell'esame.
# ==============================================================================

resource "azurerm_resource_group" "shared" {
  name     = "rg-ticketsystem-shared"
  location = var.location
  tags     = var.tags
}

module "container_registry" {
  source = "../../modules/container-registry"

  name                = "acrticketsystem${var.unique_suffix}"
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
  sku                 = "Basic"
  tags                = var.tags
}
