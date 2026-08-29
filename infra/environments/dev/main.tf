# ==============================================================================
# AMBIENTE: dev
# ==============================================================================
# Crea le risorse dell'ambiente dev: Resource Group, Log Analytics Workspace,
# Key Vault, SQL Server+Database serverless, Container Apps Environment, e le
# due Container App (ticket-api, ticket-web) che vi girano dentro.
#
# Nomi con vincoli di lunghezza/unicità globale (Key Vault max 24 caratteri,
# SQL Server deve essere globalmente unico) usano il codice progetto
# abbreviato "tkt" invece di "ticketsystem" per stare nei limiti — es.
# "kv-tkt-dev-<suffix>" invece di "kv-ticketsystem-dev-<suffix>" (che
# supererebbe i 24 caratteri).
# ==============================================================================

data "azurerm_client_config" "current" {}

# Riferimento in sola lettura allo state dell'ambiente "shared" — serve solo
# per leggere l'output acr_id/acr_login_server: dev NON gestisce l'ACR (vive
# nel suo state separato, vedi infra/environments/shared), lo referenzia e
# basta. Stesso storage account/container del backend.tf di questo ambiente.
data "terraform_remote_state" "shared" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-ticketsystem-tfstate"
    storage_account_name = "sttfstatetktj3acnr"
    container_name        = "tfstate"
    key                   = "shared.terraform.tfstate"
    use_azuread_auth      = true
  }
}

resource "azurerm_resource_group" "dev" {
  name     = "rg-ticketsystem-dev"
  location = var.location
  tags     = var.tags
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  name                 = "log-ticketsystem-dev"
  resource_group_name = azurerm_resource_group.dev.name
  location             = azurerm_resource_group.dev.location
  tags                 = var.tags
}

module "key_vault" {
  source = "../../modules/key-vault"

  name                 = "kv-tkt-dev-${var.unique_suffix}"
  resource_group_name = azurerm_resource_group.dev.name
  location             = azurerm_resource_group.dev.location
  tenant_id            = data.azurerm_client_config.current.tenant_id
  tags                 = var.tags
}

module "sql_database" {
  source = "../../modules/sql-database"

  server_name           = "sql-tkt-dev-${var.unique_suffix}"
  database_name         = "sqldb-ticketsystem-dev"
  resource_group_name   = azurerm_resource_group.dev.name
  location               = azurerm_resource_group.dev.location
  aad_admin_login_name   = var.aad_admin_login_name
  aad_admin_object_id    = var.aad_admin_object_id
  my_ip_address          = var.my_ip_address
  tags                   = var.tags
}

module "container_apps_environment" {
  source = "../../modules/container-apps-environment"

  name                        = "cae-ticketsystem-dev"
  resource_group_name        = azurerm_resource_group.dev.name
  location                    = azurerm_resource_group.dev.location
  log_analytics_workspace_id = module.log_analytics.id
  tags                        = var.tags
}

# User-Assigned Managed Identity per app, create PRIMA delle Container App:
# risolve il problema "chicken-and-egg" per cui, con un'identità di sistema,
# il ruolo AcrPull non potrebbe esistere ancora quando Azure tenta il primo
# pull dell'immagine durante la creazione stessa della Container App.
module "ticket_api_identity" {
  source = "../../modules/managed-identity"

  name                 = "id-ticket-api-dev"
  resource_group_name = azurerm_resource_group.dev.name
  location             = azurerm_resource_group.dev.location
  tags                 = var.tags
}

module "ticket_web_identity" {
  source = "../../modules/managed-identity"

  name                 = "id-ticket-web-dev"
  resource_group_name = azurerm_resource_group.dev.name
  location             = azurerm_resource_group.dev.location
  tags                 = var.tags
}

resource "azurerm_role_assignment" "ticket_api_acr_pull" {
  scope                = data.terraform_remote_state.shared.outputs.acr_id
  role_definition_name = "AcrPull"
  principal_id          = module.ticket_api_identity.principal_id
}

resource "azurerm_role_assignment" "ticket_web_acr_pull" {
  scope                = data.terraform_remote_state.shared.outputs.acr_id
  role_definition_name = "AcrPull"
  principal_id          = module.ticket_web_identity.principal_id
}

# Storage per gli allegati dei ticket — un solo container, usato solo da
# ticket-api (ticket-web non ha mai accesso diretto ai file, passa sempre
# dall'API).
module "attachments_storage" {
  source = "../../modules/storage-account"

  name                 = "sttktdev${var.unique_suffix}"
  resource_group_name = azurerm_resource_group.dev.name
  location             = azurerm_resource_group.dev.location
  tags                 = var.tags
}

resource "azurerm_role_assignment" "ticket_api_storage_blob_contributor" {
  scope                = module.attachments_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id          = module.ticket_api_identity.principal_id
}

# ticket-api: NON esposta pubblicamente (external_ingress = false) — la
# chiama solo ticket-web, dentro lo stesso Container Apps Environment.
module "ticket_api" {
  source = "../../modules/container-app"

  name                          = "ticket-api-dev"
  resource_group_name          = azurerm_resource_group.dev.name
  location                      = azurerm_resource_group.dev.location
  container_app_environment_id = module.container_apps_environment.id
  registry_server               = data.terraform_remote_state.shared.outputs.acr_login_server
  image                          = "${data.terraform_remote_state.shared.outputs.acr_login_server}/ticket-api:${var.image_tag}"
  target_port                   = 8080
  external_ingress              = false
  identity_id                   = module.ticket_api_identity.id

  env_vars = {
    # Authentication=Active Directory Managed Identity + User Id=<client_id>:
    # necessario specificare quale identità usare perché è User-Assigned
    # (con System-Assigned basterebbe "Active Directory Managed Identity"
    # da sola). Nessuna password. L'identità deve però essere prima creata
    # come utente nel database (operazione T-SQL manuale, vedi istruzioni
    # separate) prima che la connessione funzioni davvero.
    ConnectionStrings__TicketDb = "Server=tcp:${module.sql_database.server_fqdn},1433;Initial Catalog=${module.sql_database.database_name};Authentication=Active Directory Managed Identity;User Id=${module.ticket_api_identity.client_id};Encrypt=True;"
    Storage__ContainerUri       = module.attachments_storage.container_uri
  }

  tags = var.tags

  depends_on = [azurerm_role_assignment.ticket_api_acr_pull, azurerm_role_assignment.ticket_api_storage_blob_contributor]
}

# ticket-web: esposta pubblicamente (external_ingress = true) — è la UI.
module "ticket_web" {
  source = "../../modules/container-app"

  name                          = "ticket-web-dev"
  resource_group_name          = azurerm_resource_group.dev.name
  location                      = azurerm_resource_group.dev.location
  container_app_environment_id = module.container_apps_environment.id
  registry_server               = data.terraform_remote_state.shared.outputs.acr_login_server
  image                          = "${data.terraform_remote_state.shared.outputs.acr_login_server}/ticket-web:${var.image_tag}"
  target_port                   = 8080
  external_ingress              = true
  identity_id                   = module.ticket_web_identity.id

  env_vars = {
    TicketApi__BaseUrl = "https://${module.ticket_api.fqdn}/"
  }

  tags = var.tags

  depends_on = [azurerm_role_assignment.ticket_web_acr_pull]
}
