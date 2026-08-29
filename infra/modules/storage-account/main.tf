# ==============================================================================
# MODULO: storage-account
# ==============================================================================
# Cosa fa: crea uno storage account + un blob container privato, usati da
# ticket-api per salvare gli allegati dei ticket (screenshot, log file).
#
# shared_access_key_enabled = false — stesso principio già applicato allo
# storage account dello state Terraform: unica autenticazione possibile è
# Azure AD/RBAC (Managed Identity di ticket-api), nessuna Storage Account
# Key da proteggere/ruotare.
#
# container_access_type = "private": nessun accesso anonimo, nemmeno in
# lettura — ogni download passa per ticket-api, che verifica i permessi
# dell'utente sul ticket prima di restituire il file.
#
# RILEVANZA AZ-305: stesso tema "identity-based access over shared keys"
# (Zero Trust, pilastro Security del WAF) già visto per lo storage dello
# state Terraform — qui applicato ai dati applicativi.
# ==============================================================================

resource "azurerm_storage_account" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location             = var.location

  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  tags = var.tags
}

resource "azurerm_storage_container" "this" {
  name                  = var.container_name
  storage_account_name = azurerm_storage_account.this.name
  container_access_type = "private"
}
