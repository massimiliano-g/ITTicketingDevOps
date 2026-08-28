#Requires -Version 5.1
<#
==============================================================================
BOOTSTRAP DELLO STATE TERRAFORM (versione PowerShell)
==============================================================================
Va eseguito UNA SOLA VOLTA, manualmente, PRIMA di qualsiasi "terraform init".
Crea Resource Group + Storage Account + Blob Container per ospitare lo state
remoto di Terraform.

Perché manuale: Terraform ha bisogno di un backend per salvare il proprio
state PRIMA di poter creare risorse - quindi il backend stesso non può
essere creato da Terraform usando lo stesso state (problema "chicken-egg").

RILEVANZA AZ-305: bootstrap manuale minimo + IaC per tutto il resto è un
pattern di governance dell'infrastruttura come codice testato nell'esame.
==============================================================================
#>

$ErrorActionPreference = "Stop"

# --- Variabili -----------------------------------------------------------
$Location       = "switzerlandnorth"   # regione più vicina a te (Ticino).
                                        # AZ-305: la regione impatta latenza,
                                        # data residency e disponibilità servizi.
$ResourceGroup   = "rg-ticketsystem-tfstate"
$RandomSuffix    = -join ((48..57) + (97..122) | Get-Random -Count 6 | ForEach-Object {[char]$_})
$StorageAccount  = "sttfstatetkt$RandomSuffix"   # nome globalmente unico,
                                                  # max 24 caratteri, solo minuscole/numeri
$ContainerName   = "tfstate"

Write-Host "Storage account che verra' creato: $StorageAccount"
Write-Host "(salvalo, ti servira' per configurare i backend.tf)"

# --- 1. Resource Group -----------------------------------------------------
# Resource Group dedicato SOLO allo stato Terraform, separato dal resto.
# AZ-305: il resource group come confine di lifecycle e gestione accessi -
# questo RG non va mai distrutto insieme all'infrastruttura applicativa.
az group create `
  --name $ResourceGroup `
  --location $Location `
  --tags project=ticketsystem purpose=terraform-state managed-by=manual-bootstrap

# --- 2. Storage Account ------------------------------------------------------
# Standard_LRS: ridondanza locale, sufficiente per un progetto di test in
# singola regione. AZ-305: LRS vs ZRS vs GRS vs GZRS dipende da RPO/RTO
# richiesti - per un progetto di test, LRS e' la scelta piu' economica
# e giustificabile.
az storage account create `
  --name $StorageAccount `
  --resource-group $ResourceGroup `
  --location $Location `
  --sku Standard_LRS `
  --kind StorageV2 `
  --https-only true `
  --min-tls-version TLS1_2 `
  --allow-blob-public-access false `
  --allow-shared-key-access false `
  --tags project=ticketsystem purpose=terraform-state
# --allow-shared-key-access false: disabilita l'autenticazione via Storage
# Account Key. Da questo momento l'UNICO modo di accedere e' tramite
# identita' Azure AD (RBAC). AZ-305: "identity-based access over shared
# keys / Zero Trust" - tema ricorrente del Well-Architected Framework
# (pilastro Security).

# --- 3. Versioning + Soft Delete sui blob -----------------------------------
# Se lo state viene sovrascritto male o corrotto, puoi recuperare una
# versione precedente. AZ-305: "backup e disaster recovery" applicato a un
# caso pratico, stesso principio testato per storage/database.
az storage account blob-service-properties update `
  --account-name $StorageAccount `
  --resource-group $ResourceGroup `
  --enable-versioning true `
  --enable-delete-retention true `
  --delete-retention-days 7

# --- 4. Container per lo state ----------------------------------------------
# --auth-mode login: usa la TUA identita' Azure AD corrente (az login), non
# una chiave. Coerente con --allow-shared-key-access false impostato sopra.
az storage container create `
  --name $ContainerName `
  --account-name $StorageAccount `
  --auth-mode login `
  --public-access off

# --- 5. Assegnazione RBAC ----------------------------------------------------
# Ti assegna il ruolo "Storage Blob Data Contributor" sullo storage account,
# necessario per leggere/scrivere lo state via Azure AD auth.
# AZ-305: scoping del ruolo al livello piu' basso possibile (qui: singolo
# storage account, non subscription) e' il principio del "least privilege".
$SubscriptionId = az account show --query id -o tsv
$UserObjectId   = az ad signed-in-user show --query id -o tsv

az role assignment create `
  --assignee $UserObjectId `
  --role "Storage Blob Data Contributor" `
  --scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Storage/storageAccounts/$StorageAccount"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Bootstrap completato."
Write-Host "Resource Group : $ResourceGroup"
Write-Host "Storage Account: $StorageAccount"
Write-Host "Container      : $ContainerName"
Write-Host ""
Write-Host "Copia il valore di Storage Account nei file backend.tf di"
Write-Host "ogni ambiente (infra/environments/*/backend.tf)."
Write-Host "=============================================================="
