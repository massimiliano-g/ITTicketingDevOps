# ==============================================================================
# MODULO: managed-identity
# ==============================================================================
# Cosa fa: crea una User-Assigned Managed Identity — un'identità con
# lifecycle PROPRIO, indipendente da qualsiasi risorsa che la userà.
#
# Perché User-Assigned invece di System-Assigned per le Container App: con
# un'identità di sistema, l'identità nasce insieme alla risorsa che la
# possiede (qui: la Container App) — quindi non può avere un ruolo RBAC
# assegnato PRIMA che quella risorsa esista. Per una Container App che deve
# scaricare la propria immagine dall'ACR usando quella stessa identità fin
# dal primo avvio, questo crea una corsa: Azure tenta il pull dell'immagine
# durante la creazione stessa della Container App, prima che Terraform possa
# assegnare il ruolo AcrPull (che dipende dal principal_id, noto solo DOPO
# che la Container App esiste).
#
# Con una User-Assigned Identity creata come risorsa separata, il ruolo
# AcrPull viene assegnato PRIMA che qualunque Container App la usi — nessuna
# corsa, il primo pull dell'immagine funziona al primo tentativo.
#
# RILEVANZA AZ-305: la scelta tra System-Assigned e User-Assigned Managed
# Identity (lifecycle legato alla risorsa vs indipendente, 1:1 vs
# riutilizzabile su più risorse) è un confronto esplicito dell'esame nel
# contesto di identity-based access.
# ==============================================================================

resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}
