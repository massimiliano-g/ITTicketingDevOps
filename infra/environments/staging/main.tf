# ==============================================================================
# AMBIENTE: staging
# ==============================================================================
# Stesso identico schema di dev — stessi moduli riutilizzabili, stesse
# scelte serverless/scale-to-zero per restare a costo minimo. L'unica
# differenza rilevante rispetto a dev è nel nome delle risorse
# (segmento "staging" invece di "dev") e nel fatto che il deploy passa
# dietro un'approvazione manuale nella pipeline (GitHub Environment).
# ==============================================================================

data "azurerm_client_config" "current" {}

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

resource "azurerm_resource_group" "staging" {
  name     = "rg-ticketsystem-staging"
  location = var.location
  tags     = var.tags
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  name                 = "log-ticketsystem-staging"
  resource_group_name = azurerm_resource_group.staging.name
  location             = azurerm_resource_group.staging.location
  tags                 = var.tags
}

module "key_vault" {
  source = "../../modules/key-vault"

  name                 = "kv-tkt-staging-${var.unique_suffix}"
  resource_group_name = azurerm_resource_group.staging.name
  location             = azurerm_resource_group.staging.location
  tenant_id            = data.azurerm_client_config.current.tenant_id
  tags                 = var.tags
}

module "sql_database" {
  source = "../../modules/sql-database"

  server_name           = "sql-tkt-staging-${var.unique_suffix}"
  database_name         = "sqldb-ticketsystem-staging"
  resource_group_name   = azurerm_resource_group.staging.name
  location               = azurerm_resource_group.staging.location
  aad_admin_login_name   = var.aad_admin_login_name
  aad_admin_object_id    = var.aad_admin_object_id
  my_ip_address          = var.my_ip_address
  tags                   = var.tags
}

module "container_apps_environment" {
  source = "../../modules/container-apps-environment"

  name                        = "cae-ticketsystem-staging"
  resource_group_name        = azurerm_resource_group.staging.name
  location                    = azurerm_resource_group.staging.location
  log_analytics_workspace_id = module.log_analytics.id
  tags                        = var.tags
}

module "ticket_api_identity" {
  source = "../../modules/managed-identity"

  name                 = "id-ticket-api-staging"
  resource_group_name = azurerm_resource_group.staging.name
  location             = azurerm_resource_group.staging.location
  tags                 = var.tags
}

module "ticket_web_identity" {
  source = "../../modules/managed-identity"

  name                 = "id-ticket-web-staging"
  resource_group_name = azurerm_resource_group.staging.name
  location             = azurerm_resource_group.staging.location
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

module "attachments_storage" {
  source = "../../modules/storage-account"

  name                 = "sttktstaging${var.unique_suffix}"
  resource_group_name = azurerm_resource_group.staging.name
  location             = azurerm_resource_group.staging.location
  tags                 = var.tags
}

resource "azurerm_role_assignment" "ticket_api_storage_blob_contributor" {
  scope                = module.attachments_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id          = module.ticket_api_identity.principal_id
}

module "ticket_api" {
  source = "../../modules/container-app"

  name                          = "ticket-api-staging"
  resource_group_name          = azurerm_resource_group.staging.name
  location                      = azurerm_resource_group.staging.location
  container_app_environment_id = module.container_apps_environment.id
  registry_server               = data.terraform_remote_state.shared.outputs.acr_login_server
  image                          = "${data.terraform_remote_state.shared.outputs.acr_login_server}/ticket-api:${var.image_tag}"
  target_port                   = 8080
  external_ingress              = false
  identity_id                   = module.ticket_api_identity.id

  env_vars = {
    ConnectionStrings__TicketDb = "Server=tcp:${module.sql_database.server_fqdn},1433;Initial Catalog=${module.sql_database.database_name};Authentication=Active Directory Managed Identity;User Id=${module.ticket_api_identity.client_id};Encrypt=True;"
    Storage__ContainerUri       = module.attachments_storage.container_uri
  }

  tags = var.tags

  depends_on = [azurerm_role_assignment.ticket_api_acr_pull, azurerm_role_assignment.ticket_api_storage_blob_contributor]
}

module "ticket_web" {
  source = "../../modules/container-app"

  name                          = "ticket-web-staging"
  resource_group_name          = azurerm_resource_group.staging.name
  location                      = azurerm_resource_group.staging.location
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
