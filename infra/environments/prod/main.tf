# ==============================================================================
# AMBIENTE: prod
# ==============================================================================
# Stesso identico schema di dev/staging. Deploy sempre dietro approvazione
# manuale nella pipeline (GitHub Environment "prod").
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

resource "azurerm_resource_group" "prod" {
  name     = "rg-ticketsystem-prod"
  location = var.location
  tags     = var.tags
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  name                 = "log-ticketsystem-prod"
  resource_group_name = azurerm_resource_group.prod.name
  location             = azurerm_resource_group.prod.location
  tags                 = var.tags
}

module "key_vault" {
  source = "../../modules/key-vault"

  name                 = "kv-tkt-prod-${var.unique_suffix}"
  resource_group_name = azurerm_resource_group.prod.name
  location             = azurerm_resource_group.prod.location
  tenant_id            = data.azurerm_client_config.current.tenant_id
  tags                 = var.tags
}

module "sql_database" {
  source = "../../modules/sql-database"

  server_name           = "sql-tkt-prod-${var.unique_suffix}"
  database_name         = "sqldb-ticketsystem-prod"
  resource_group_name   = azurerm_resource_group.prod.name
  location               = azurerm_resource_group.prod.location
  aad_admin_login_name   = var.aad_admin_login_name
  aad_admin_object_id    = var.aad_admin_object_id
  my_ip_address          = var.my_ip_address
  tags                   = var.tags
}

module "container_apps_environment" {
  source = "../../modules/container-apps-environment"

  name                        = "cae-ticketsystem-prod"
  resource_group_name        = azurerm_resource_group.prod.name
  location                    = azurerm_resource_group.prod.location
  log_analytics_workspace_id = module.log_analytics.id
  tags                        = var.tags
}

module "ticket_api_identity" {
  source = "../../modules/managed-identity"

  name                 = "id-ticket-api-prod"
  resource_group_name = azurerm_resource_group.prod.name
  location             = azurerm_resource_group.prod.location
  tags                 = var.tags
}

module "ticket_web_identity" {
  source = "../../modules/managed-identity"

  name                 = "id-ticket-web-prod"
  resource_group_name = azurerm_resource_group.prod.name
  location             = azurerm_resource_group.prod.location
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

module "ticket_api" {
  source = "../../modules/container-app"

  name                          = "ticket-api-prod"
  resource_group_name          = azurerm_resource_group.prod.name
  location                      = azurerm_resource_group.prod.location
  container_app_environment_id = module.container_apps_environment.id
  registry_server               = data.terraform_remote_state.shared.outputs.acr_login_server
  image                          = "${data.terraform_remote_state.shared.outputs.acr_login_server}/ticket-api:${var.image_tag}"
  target_port                   = 8080
  external_ingress              = false
  identity_id                   = module.ticket_api_identity.id

  env_vars = {
    ConnectionStrings__TicketDb = "Server=tcp:${module.sql_database.server_fqdn},1433;Initial Catalog=${module.sql_database.database_name};Authentication=Active Directory Managed Identity;User Id=${module.ticket_api_identity.client_id};Encrypt=True;"
  }

  tags = var.tags

  depends_on = [azurerm_role_assignment.ticket_api_acr_pull]
}

module "ticket_web" {
  source = "../../modules/container-app"

  name                          = "ticket-web-prod"
  resource_group_name          = azurerm_resource_group.prod.name
  location                      = azurerm_resource_group.prod.location
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
