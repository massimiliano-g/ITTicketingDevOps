# ==============================================================================
# AMBIENTE: github-oidc
# ==============================================================================
# Crea le identità con cui GitHub Actions si autentica su Azure — una per
# ambiente (dev/staging/prod), ciascuna con permessi SOLO sul proprio
# ambiente ("blast radius" ridotto: una pipeline compromessa che punta a dev
# non può toccare prod).
#
# OIDC / Federated Identity Credential — alternative valutate:
# - Service Principal + client secret salvato come GitHub Secret (pattern
#   "classico"): un secret di lunga durata, da ruotare manualmente, che se
#   trapela resta valido finché non lo revochi. È il pattern che il briefing
#   originale del progetto voleva esplicitamente evitare.
# - OIDC/Federated Credentials (scelta): GitHub genera un token OIDC
#   short-lived ad ogni esecuzione del workflow; Entra ID lo scambia con un
#   access token Azure SOLO se il token proviene da un repository/branch/
#   environment specifico (il "subject claim", verificato tramite
#   azurerm_federated_identity_credential). Nessun secret salvato da
#   nessuna parte, nessuna rotazione da gestire.
#
# User-Assigned Identity invece di App Registration classica: stesso
# ragionamento già fatto per le Container App (vedi modulo managed-identity)
# — lifecycle gestito da Terraform/RBAC nativo, non serve creare
# un'Application Entra ID separata con permessi Microsoft Graph.
#
# RILEVANZA AZ-305: OIDC/Workload Identity Federation come alternativa
# passwordless ai service principal con secret è un tema esplicito del
# pilastro Security del Well-Architected Framework, applicato qui alla CI/CD
# invece che al runtime applicativo (dove lo abbiamo già usato per le
# Container App verso ACR/SQL).
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

data "terraform_remote_state" "dev" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-ticketsystem-tfstate"
    storage_account_name = "sttfstatetktj3acnr"
    container_name        = "tfstate"
    key                   = "dev.terraform.tfstate"
    use_azuread_auth      = true
  }
}

data "terraform_remote_state" "staging" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-ticketsystem-tfstate"
    storage_account_name = "sttfstatetktj3acnr"
    container_name        = "tfstate"
    key                   = "staging.terraform.tfstate"
    use_azuread_auth      = true
  }
}

data "terraform_remote_state" "prod" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-ticketsystem-tfstate"
    storage_account_name = "sttfstatetktj3acnr"
    container_name        = "tfstate"
    key                   = "prod.terraform.tfstate"
    use_azuread_auth      = true
  }
}

# Scope del ruolo Storage Blob Data Contributor: il CONTAINER blob "tfstate"
# (non l'intero storage account) — tutti gli state (dev/staging/prod)
# condividono lo stesso container (scelta fatta per semplicità nel bootstrap
# iniziale), quindi questa è la granularità più fine possibile con la
# struttura attuale. Limite noto: l'identità di prod può tecnicamente
# leggere/scrivere anche lo state di dev, dato che RBAC Azure non scende a
# livello di singolo blob. Per isolamento completo servirebbero container
# separati per ambiente — miglioria futura, non implementata qui per
# restare aderenti al bootstrap già eseguito.
locals {
  tfstate_container_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/rg-ticketsystem-tfstate/providers/Microsoft.Storage/storageAccounts/sttfstatetktj3acnr/blobServices/default/containers/tfstate"
}

resource "azurerm_resource_group" "cicd" {
  name     = "rg-ticketsystem-cicd"
  location = var.location
  tags     = var.tags
}

# ------------------------------------------------------------------------------
# Identità dev
# ------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "dev" {
  name                = "id-github-oidc-dev"
  resource_group_name = azurerm_resource_group.cicd.name
  location             = azurerm_resource_group.cicd.location
  tags                 = var.tags
}

# Subject "pull_request": usato dal job di "terraform plan" sulle PR — deve
# poter girare SENZA approvazione manuale (è solo un plan, nessuna modifica
# reale), quindi non è legato a un GitHub Environment.
resource "azurerm_federated_identity_credential" "dev_pull_request" {
  name                = "github-pull-request"
  parent_id           = azurerm_user_assigned_identity.dev.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repository}:pull_request"
}

# Subject "environment:dev": usato dal job di apply su dev dopo il merge —
# legato al GitHub Environment "dev" (senza reviewer richiesti: dev applica
# automaticamente, coerente con l'iterazione rapida voluta per questo
# ambiente).
resource "azurerm_federated_identity_credential" "dev_environment" {
  name                = "github-environment-dev"
  parent_id           = azurerm_user_assigned_identity.dev.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repository}:environment:dev"
}

resource "azurerm_role_assignment" "dev_contributor" {
  scope                = data.terraform_remote_state.dev.outputs.resource_group_id
  role_definition_name = "Contributor"
  principal_id          = azurerm_user_assigned_identity.dev.principal_id
}

# Contributor NON include il permesso di creare role assignment (separazione
# dei compiti voluta da Azure by design) — ma il nostro Terraform per dev
# crea role assignment AcrPull per le Container App. Serve quindi anche
# questo ruolo, scoped allo stesso Resource Group.
resource "azurerm_role_assignment" "dev_rbac_admin" {
  scope                = data.terraform_remote_state.dev.outputs.resource_group_id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id          = azurerm_user_assigned_identity.dev.principal_id
}

# Stesso ruolo, ma scoped alla sola ACR condivisa: serve perché dev crea
# role assignment AcrPull PROPRIO SULL'ACR, che vive nel Resource Group
# "shared", fuori dallo scope sopra.
resource "azurerm_role_assignment" "dev_rbac_admin_acr" {
  scope                = data.terraform_remote_state.shared.outputs.acr_id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id          = azurerm_user_assigned_identity.dev.principal_id
}

resource "azurerm_role_assignment" "dev_state_access" {
  scope                = local.tfstate_container_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id          = azurerm_user_assigned_identity.dev.principal_id
}

# Serve alla pipeline applicativa (build+push immagine) — è l'unica identità
# a costruire/pushare, coerente col pattern "build once, promote many":
# staging/prod referenziano la stessa immagine via tag, non la ricostruiscono.
resource "azurerm_role_assignment" "dev_acr_push" {
  scope                = data.terraform_remote_state.shared.outputs.acr_id
  role_definition_name = "AcrPush"
  principal_id          = azurerm_user_assigned_identity.dev.principal_id
}

# ------------------------------------------------------------------------------
# Identità staging
# ------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "staging" {
  name                = "id-github-oidc-staging"
  resource_group_name = azurerm_resource_group.cicd.name
  location             = azurerm_resource_group.cicd.location
  tags                 = var.tags
}

# Solo subject "environment:staging": staging non ha un job di plan-su-PR
# dedicato, viene promosso solo tramite il job di apply dietro approvazione
# (reviewer richiesti configurati sul GitHub Environment "staging").
resource "azurerm_federated_identity_credential" "staging_environment" {
  name                = "github-environment-staging"
  parent_id           = azurerm_user_assigned_identity.staging.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repository}:environment:staging"
}

resource "azurerm_role_assignment" "staging_contributor" {
  scope                = data.terraform_remote_state.staging.outputs.resource_group_id
  role_definition_name = "Contributor"
  principal_id          = azurerm_user_assigned_identity.staging.principal_id
}

resource "azurerm_role_assignment" "staging_rbac_admin" {
  scope                = data.terraform_remote_state.staging.outputs.resource_group_id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id          = azurerm_user_assigned_identity.staging.principal_id
}

resource "azurerm_role_assignment" "staging_rbac_admin_acr" {
  scope                = data.terraform_remote_state.shared.outputs.acr_id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id          = azurerm_user_assigned_identity.staging.principal_id
}

resource "azurerm_role_assignment" "staging_state_access" {
  scope                = local.tfstate_container_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id          = azurerm_user_assigned_identity.staging.principal_id
}

# ------------------------------------------------------------------------------
# Identità prod
# ------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "prod" {
  name                = "id-github-oidc-prod"
  resource_group_name = azurerm_resource_group.cicd.name
  location             = azurerm_resource_group.cicd.location
  tags                 = var.tags
}

resource "azurerm_federated_identity_credential" "prod_environment" {
  name                = "github-environment-prod"
  parent_id           = azurerm_user_assigned_identity.prod.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repository}:environment:prod"
}

resource "azurerm_role_assignment" "prod_contributor" {
  scope                = data.terraform_remote_state.prod.outputs.resource_group_id
  role_definition_name = "Contributor"
  principal_id          = azurerm_user_assigned_identity.prod.principal_id
}

resource "azurerm_role_assignment" "prod_rbac_admin" {
  scope                = data.terraform_remote_state.prod.outputs.resource_group_id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id          = azurerm_user_assigned_identity.prod.principal_id
}

resource "azurerm_role_assignment" "prod_rbac_admin_acr" {
  scope                = data.terraform_remote_state.shared.outputs.acr_id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id          = azurerm_user_assigned_identity.prod.principal_id
}

resource "azurerm_role_assignment" "prod_state_access" {
  scope                = local.tfstate_container_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id          = azurerm_user_assigned_identity.prod.principal_id
}
