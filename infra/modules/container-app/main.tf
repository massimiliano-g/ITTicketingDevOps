# ==============================================================================
# MODULO: container-app
# ==============================================================================
# Cosa fa: crea una singola Container App dentro un Container Apps
# Environment già esistente — l'unità che effettivamente esegue un'immagine
# Docker (ticket-api o ticket-web).
#
# identity { type = "UserAssigned" } + registry { identity = <id> }: la
# Container App si autentica sull'ACR con una User-Assigned Managed Identity
# (creata come risorsa separata dal chiamante, modulo managed-identity)
# invece che con le credenziali admin dell'ACR (disabilitate, admin_enabled
# = false, nel modulo container-registry) o con un'identità di sistema.
#
# Perché NON System-Assigned: con un'identità di sistema, l'identità nasce
# insieme alla Container App — quindi il ruolo AcrPull non può esistere
# ancora quando Azure tenta il primo pull dell'immagine durante la CREAZIONE
# stessa della Container App (non solo al primo traffico: min_replicas = 0
# NON evita questo primo tentativo, a differenza di quanto si potrebbe
# pensare). Con una User-Assigned Identity creata prima e con il ruolo già
# assegnato, il primo pull funziona al primo tentativo.
#
# min_replicas di default 0 — scale-to-zero: nessuna replica (e nessun
# costo) quando non c'è traffico. Non risolve da solo il problema di
# ordinamento del pull (vedi sopra) — per quello serve la User-Assigned
# Identity.
#
# ingress.external_enabled — true per ticket-web (deve essere raggiungibile
# da un browser), false per ticket-api (chiamato solo da ticket-web dentro
# lo stesso Container Apps Environment, via il suo FQDN interno
# *.internal.<default_domain>). Nessun endpoint pubblico non necessario:
# principio di "minimal exposed surface" dello stesso tipo già applicato al
# SQL Server (regole firewall) e al Key Vault (RBAC).
#
# RILEVANZA AZ-305: la scelta ingress interno vs esterno per servizi che
# comunicano tra loro dentro lo stesso ambiente è lo stesso principio di
# "network segmentation"/minimal exposure testato per subnet/NSG in
# ambienti IaaS — qui applicato al livello PaaS di Container Apps. La scelta
# User-Assigned vs System-Assigned Identity è un confronto esplicito
# dell'esame (lifecycle indipendente vs legato alla risorsa).
# ==============================================================================

resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  registry {
    server   = var.registry_server
    identity = var.identity_id
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  ingress {
    external_enabled = var.external_ingress
    target_port      = var.target_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = var.tags
}
