# ==============================================================================
# AMBIENTE: dev
# ==============================================================================
# Crea le risorse "core" dell'ambiente dev: Resource Group, Log Analytics
# Workspace, Key Vault, SQL Server+Database serverless, Container Apps
# Environment. La Container App vera e propria (ticket-api) verrà aggiunta
# in un passo successivo, quando avremo l'immagine Docker da referenziare.
#
# Nomi con vincoli di lunghezza/unicità globale (Key Vault max 24 caratteri,
# SQL Server deve essere globalmente unico) usano il codice progetto
# abbreviato "tkt" invece di "ticketsystem" per stare nei limiti — es.
# "kv-tkt-dev-<suffix>" invece di "kv-ticketsystem-dev-<suffix>" (che
# supererebbe i 24 caratteri).
# ==============================================================================

data "azurerm_client_config" "current" {}

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
