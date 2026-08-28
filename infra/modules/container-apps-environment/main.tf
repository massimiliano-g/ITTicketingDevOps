# ==============================================================================
# MODULO: container-apps-environment
# ==============================================================================
# Cosa fa: crea l'Azure Container Apps Environment, il confine di rete/
# osservabilità/scaling condiviso da una o più Container App che ci verranno
# aggiunte dentro (es. ticket-api). Non è ancora l'app in sé — è
# l'"ambiente ospitante" (concettualmente simile a un cluster AKS "gestito",
# ma serverless).
#
# Consumption plan (default, nessun workload profile dedicato configurato)
# — alternative valutate:
# - Workload profiles dedicati (D4/D8/E-series): riservano VM dedicate per
#   carichi con requisiti hardware specifici (GPU, memory-optimized) o per
#   isolamento da altri tenant. Costo fisso anche a carico zero.
# - Consumption (scelta): niente infrastruttura riservata, si paga per
#   vCPU-secondi/GiB-secondi effettivamente usati, con scale-to-zero nativo
#   quando non ci sono richieste — coerente con l'obiettivo di costo
#   aggressivamente ottimizzato del progetto.
#
# Collegamento a Log Analytics: obbligatorio in fase di creazione
# dell'environment — è così che stdout/stderr dei container e le metriche
# di sistema (repliche attive, restart) finiscono nel workspace per query
# via Log Analytics/Application Insights.
#
# RILEVANZA AZ-305: Container Apps è uno dei servizi di hosting "compute"
# confrontati nell'esame contro App Service, AKS e Functions — Consumption
# plan con scale-to-zero è l'argomento chiave quando il caso d'uso richiede
# "cloud-native microservices senza gestione di cluster" a costo minimo in
# assenza di traffico.
# ==============================================================================

resource "azurerm_container_app_environment" "this" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = var.tags
}
