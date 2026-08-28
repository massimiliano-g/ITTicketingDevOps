# ==============================================================================
# MODULO: log-analytics
# ==============================================================================
# Cosa fa: crea un Log Analytics Workspace, che raccoglie i log e le metriche
# del Container Apps Environment (log di sistema/console dei container,
# metriche di scaling, ecc.). È un prerequisito obbligatorio per creare un
# Container Apps Environment: ogni environment deve essere collegato a un
# workspace.
#
# Un workspace PER AMBIENTE (non condiviso) — coerente con l'isolamento già
# scelto per Key Vault: i log di dev non devono mescolarsi con quelli di
# prod, sia per rumore/costo sia per evitare che dati di test finiscano
# nello stesso posto di dati (potenzialmente) più sensibili di prod.
#
# SKU — alternative valutate:
# - PerGB2018 (scelta): pay-as-you-go a consumo, nessun impegno di capacità
#   minima giornaliera. Corretto per un progetto con poco traffico e finestre
#   di test brevi.
# - Capacity Reservation (es. 100GB/giorno): sconto sul prezzo per GB ma
#   richiede un impegno di volume minimo giornaliero — conviene solo con
#   ingestion costante e prevedibile, non per un progetto di pratica.
#
# RILEVANZA AZ-305: Log Analytics Workspace è il fondamento di "Design for
# monitoring and logging" nell'esame — inclusa la scelta tra workspace
# centralizzato vs per-ambiente/team (trade-off tra costo di query
# cross-workspace e isolamento/governance dei dati), e la scelta dello SKU
# di pricing (pay-as-you-go vs capacity reservation).
# ==============================================================================

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days

  tags = var.tags
}
