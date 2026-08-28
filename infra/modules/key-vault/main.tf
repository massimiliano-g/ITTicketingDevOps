# ==============================================================================
# MODULO: key-vault
# ==============================================================================
# Cosa fa: crea un Azure Key Vault per ambiente (dev/staging/prod), destinato
# a ospitare i secret dell'app (es. connection string SQL, se non si usa
# autenticazione AAD end-to-end).
#
# Uno per ambiente, non condiviso — isolamento: un leak/errore RBAC in dev
# non deve poter esporre i secret di prod. Coerente con l'isolamento già
# scelto per il Log Analytics Workspace.
#
# rbac_authorization_enabled = true — alternative valutate:
# - Access Policies (legacy): modello di autorizzazione precedente, gestito
#   dentro la risorsa Key Vault stessa, non integrato con Entra ID RBAC —
#   niente Privileged Identity Management, niente scoping granulare per
#   singola operazione (get/list/set separati da modello ad-hoc).
# - RBAC (scelta): stesso modello di autorizzazione usato per tutte le altre
#   risorse Azure (ruoli come "Key Vault Secrets Officer/User" assegnabili
#   su scope Vault/RG/subscription), auditabile in Entra ID, coerente con
#   Managed Identity dei Container Apps e con l'autenticazione OIDC della CI.
#
# purge_protection_enabled = false — scelta deliberata per QUESTO progetto:
# con purge protection attiva, un Key Vault eliminato resta in stato
# "soft-deleted" per soft_delete_retention_days e IMPEDISCE la creazione di
# un nuovo vault con lo stesso nome fino alla scadenza (a meno di un purge
# esplicito, che richiede comunque un ruolo dedicato). Per un progetto con
# cicli rapidi di `terraform destroy`/`apply` in un tenant di test, questo
# comportamento sarebbe solo attrito. In un ambiente reale/prod, purge
# protection è la scelta corretta per prevenire cancellazioni distruttive
# irreversibili dei secret.
#
# RILEVANZA AZ-305: Key Vault RBAC vs Access Policies, e soft-delete/purge
# protection come meccanismo di "recovery from accidental deletion", sono
# entrambi temi espliciti del pilastro Security del Well-Architected
# Framework testato nell'esame.
# ==============================================================================

resource "azurerm_key_vault" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled  = true
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7 # minimo consentito da Azure

  tags = var.tags
}
