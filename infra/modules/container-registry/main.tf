# ==============================================================================
# MODULO: container-registry
# ==============================================================================
# Cosa fa: crea un Azure Container Registry (ACR), il registry privato dove
# le immagini Docker dell'app (es. ticket-api) vengono pubblicate dalla CI e
# poi tirate giù dai Container Apps in dev/staging/prod.
#
# Pattern "build once, promote many": una singola immagine viene taggata e
# promossa tra gli ambienti (es. dev -> staging -> prod), invece di essere
# ricostruita per ognuno — per questo l'ACR vive nell'ambiente "shared" e
# viene referenziato (non ricreato) dagli altri ambienti.
#
# SKU — alternative valutate:
# - Basic (scelta): throughput e storage limitati, nessuna geo-replica,
#   nessun private endpoint. Sufficiente per un progetto di pratica con un
#   solo team e una sola regione.
# - Standard: più throughput/storage, stesso limite su geo-replica/private
#   link. Utile se il volume di push/pull cresce.
# - Premium: sblocca geo-replicazione multi-regione, private endpoints,
#   customer-managed keys, content trust. Necessario in scenari enterprise
#   multi-regione con requisiti di alta disponibilità del registry stesso.
#
# admin_enabled = false — alternative valutate:
# - Admin account (username/password singolo, condiviso): sconsigliato in
#   produzione, non è auditabile per-utente e le credenziali sono statiche.
# - Managed Identity + ruoli RBAC (AcrPush/AcrPull) — scelta: ogni identità
#   (GitHub Actions via OIDC, Container App) ottiene un ruolo puntuale,
#   revocabile singolarmente e tracciato in Entra ID.
#
# RILEVANZA AZ-305: ACR è testato nell'esame sotto "Design infrastructure
# solutions" — in particolare la scelta tra SKU (throughput/geo-replica) e
# il pattern "build once, deploy many" con promozione delle immagini tra
# ambienti tramite tag. La disabilitazione dell'admin account e l'uso di
# Managed Identity + RBAC riflettono il principio "least privilege" testato
# anche per Key Vault e Storage Account.
# ==============================================================================

resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false

  tags = var.tags
}
