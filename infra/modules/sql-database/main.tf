# ==============================================================================
# MODULO: sql-database
# ==============================================================================
# Cosa fa: crea un logical SQL Server + un database Azure SQL in modalità
# Serverless, General Purpose — il backing store del microservizio
# ticket-api.
#
# Serverless vs Provisioned — alternative valutate:
# - Provisioned (vCore fissi sempre allocati, es. GP_Gen5_2): prevedibile
#   nelle performance, fatturato H24 indipendentemente dall'uso. Corretto
#   per carichi costanti/prod con traffico prevedibile.
# - Serverless (scelta): scala automaticamente i vCore tra min_capacity e
#   il max dello SKU in base al carico, E VA IN AUTO-PAUSE dopo
#   auto_pause_delay_in_minutes di inattività — compute fatturato a zero
#   mentre è in pausa (si paga solo lo storage). Corretto per un progetto
#   con finestre di test brevi e intermittenti: è la leva di risparmio più
#   importante di tutto il progetto insieme all'auto-pause dei Container
#   Apps in scale-to-zero.
# - Hyperscale: tier pensato per database molto grandi (>100GB) con
#   requisiti di scaling storage indipendenti dal compute e read-replica
#   multiple — over-engineering per un ticket system di pratica.
#
# DTU vs vCore — scelta esplicita vCore (General Purpose Serverless): il
# modello DTU (Basic/Standard/Premium) è un bundle opaco di CPU/memoria/IO
# che non consente scaling granulare né la modalità serverless; il modello
# vCore separa compute e storage e offre trasparenza sui costi e sulla
# scelta hardware (Gen5). L'esame AZ-305 tratta esplicitamente questo
# confronto come criterio di scelta.
#
# Autenticazione — azuread_administrator con azuread_authentication_only =
# true: il server NON ha alcun login SQL nativo (niente
# administrator_login/administrator_login_password) — l'UNICO modo di
# amministrare il server è tramite un'identità Entra ID. Questo è il
# pattern "passwordless"/Zero Trust dello stesso principio già applicato
# allo storage account dello state Terraform (--allow-shared-key-access
# false). L'app dovrà autenticarsi via Managed Identity/Azure AD token
# invece che con user/password nella connection string — verrà configurato
# quando scriveremo ticket-api.
#
# Rete — accesso pubblico + firewall IP, non Private Endpoint: per un
# progetto senza VNet il Private Endpoint (che richiederebbe una rete
# virtuale con subnet dedicata e Private DNS Zone) sarebbe complessità non
# giustificata. La regola "AllowAzureServices" (0.0.0.0-0.0.0.0) è
# necessaria perché il Container Apps Environment consumption non ha
# VNet integration di default, quindi raggiunge SQL dal suo endpoint
# pubblico.
#
# RILEVANZA AZ-305: DTU vs vCore, Provisioned vs Serverless vs Hyperscale,
# e Public Endpoint+firewall vs Private Endpoint sono TUTTI temi
# esplicitamente testati in "Design data storage solutions" — insieme al
# principio di autenticazione Entra-only/passwordless del pilastro Security
# del Well-Architected Framework.
# ==============================================================================

resource "azurerm_mssql_server" "this" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  minimum_tls_version          = "1.2"
  public_network_access_enabled = true

  azuread_administrator {
    login_username              = var.aad_admin_login_name
    object_id                   = var.aad_admin_object_id
    azuread_authentication_only = true
  }

  tags = var.tags
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "allow_my_ip" {
  count = var.my_ip_address != null ? 1 : 0

  name             = "AllowMyIp"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = var.my_ip_address
  end_ip_address   = var.my_ip_address
}

resource "azurerm_mssql_database" "this" {
  name      = var.database_name
  server_id = azurerm_mssql_server.this.id

  sku_name                    = var.sku_name
  max_size_gb                 = var.max_size_gb
  min_capacity                 = var.min_capacity
  auto_pause_delay_in_minutes = var.auto_pause_delay_in_minutes
  zone_redundant               = false

  tags = var.tags
}
