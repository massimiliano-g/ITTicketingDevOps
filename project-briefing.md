# Briefing progetto: Ticket Management System — Azure + Terraform + GitHub Actions

## Contesto
Sto costruendo un progetto di pratica DevOps: un sistema semplificato di gestione
ticket IT, per esercitarmi con Terraform + Azure + GitHub Actions seguendo le
best practice del settore. Sto anche studiando per la certificazione AZ-305
(Azure Solutions Architect), quindi per ogni risorsa Azure che creiamo voglio:
- una spiegazione dettagliata di cosa fa
- le alternative valutate e perché NON le abbiamo scelte
- la rilevanza specifica per l'esame AZ-305 (concetti/keyword che l'esame testa)

## Vincoli del progetto
- Deploy su un tenant Azure di **test** personale (non produzione reale)
- Finestra di lavoro: pochi giorni di test attivo → **costo da ottimizzare
  aggressivamente** (scale-to-zero, serverless con auto-pause, no HA dove
  non necessario, `terraform destroy` a fine sessione)
- Regione Azure: **switzerlandnorth**
- Livello di complessità voluto: **avanzato** — 3 ambienti (dev/staging/prod)
  con approvazioni manuali nella pipeline verso staging→prod

## Stack tecnico deciso
| Livello | Scelta | Perché (in breve) |
|---|---|---|
| Backend applicativo | .NET (C#) | preferenza esplicita |
| Hosting container | **Azure Container Apps** (Consumption plan), non AKS | supporta microservizi/cloud-native (Dapr, service discovery) con molto meno overhead operativo di AKS — scelta deliberata per restare focalizzati su Terraform/CI-CD invece che su cluster management |
| Database | **Azure SQL Database, Serverless, General Purpose** (non PostgreSQL) | scelta esplicita per allinearsi ai contenuti AZ-305 (DTU vs vCore, serverless vs provisioned, Hyperscale); auto-pause dopo 60 min di inattività azzera i costi di compute quando non sto testando |
| Container Registry | Azure Container Registry (Basic), **condiviso tra tutti gli ambienti** | pattern "build once, promote many": la stessa immagine Docker viene promossa attraverso dev→staging→prod via tag, non ricostruita per ogni ambiente |
| Secret management | Key Vault, **uno per ambiente** (non condiviso) | isolamento: un leak in dev non deve esporre secret di prod. RBAC authorization abilitata (no Access Policies legacy) |
| Osservabilità | Log Analytics Workspace per ambiente | collegato al Container Apps Environment |
| IaC | Terraform, backend remoto `azurerm` | state separato per ambiente (container blob condiviso, key diversa per env) |
| CI/CD | GitHub Actions, autenticazione via **OIDC/Federated Credentials** (no client secret salvati) | non ancora implementato — prossimo step |

## Decisioni di sicurezza/governance già prese
- Storage account per lo state Terraform: `--allow-shared-key-access false`
  (solo autenticazione Azure AD/RBAC, niente Storage Account Key)
- Versioning + soft delete (7gg) abilitati sul blob container dello state,
  per recovery in caso di state corrotto
- Container Registry: `admin_enabled = false`, accesso solo via Managed
  Identity + ruoli RBAC (AcrPush/AcrPull) — non ancora configurato nel
  dettaglio, da fare quando arriviamo alla pipeline
- Azure SQL: amministratore Azure AD configurato sul server invece del solo
  login SQL classico
- Naming convention ispirata ad Azure CAF: `rg-ticketsystem-<env>`,
  `sql-ticketsystem-<env>-<suffix>`, ecc.

## Stato attuale — cosa è FATTO
- [x] Script di bootstrap dello state Terraform eseguito con successo
      (versione PowerShell, `00-bootstrap-tfstate.ps1`): ha creato
      Resource Group `rg-ticketsystem-tfstate` + uno Storage Account
      dedicato + container blob `tfstate`, con versioning/soft-delete e
      RBAC assegnato alla mia identità
- [x] `backend.tf` dell'ambiente `dev` configurato con il nome reale dello
      storage account (placeholder sostituito)
- [x] `terraform init` eseguito con successo su `infra/environments/dev`
      (output: "Terraform has been successfully initialized!")

## Stato attuale — cosa NON è ancora fatto
- [ ] I file Terraform dei **moduli riutilizzabili** sono stati generati
      nella chat precedente ma **non sono ancora stati copiati** nella
      cartella locale del progetto:
      `infra/modules/{log-analytics, container-registry, key-vault,
      sql-database, container-apps-environment}/main.tf`
- [ ] I file degli **ambienti** `shared`, `staging`, `prod` (main.tf,
      variables.tf, outputs.tf, backend.tf, terraform.tfvars.example)
      sono stati generati ma **non copiati**. Solo `dev/backend.tf` è a
      posto; `dev/main.tf`, `dev/variables.tf`, `dev/outputs.tf` NON
      sono ancora nella cartella locale
- [ ] `backend.tf` di `shared`, `staging`, `prod` hanno ancora il
      placeholder `REPLACE_WITH_YOUR_STORAGE_ACCOUNT_NAME` da sostituire
      con il nome reale dello storage account
- [ ] Nessun `terraform.tfvars` reale creato in nessun ambiente (servono
      `unique_suffix`, `aad_admin_login_name`, opzionale `my_ip_address`)
- [ ] `terraform validate` / `plan` / `apply` **non ancora eseguiti** da
      nessuna parte — solo `init` su dev
- [ ] `.gitignore` generato ma non copiato nel repo locale
- [ ] Nessuna applicazione .NET ancora scritta
- [ ] Nessuna pipeline GitHub Actions ancora scritta
- [ ] Autenticazione OIDC GitHub→Azure non configurata

## Struttura di cartelle attesa (target)
```
IT Ticketing DevOps System/
├── .gitignore
├── README.md
├── bootstrap/
│   ├── 00-bootstrap-tfstate.sh
│   └── 00-bootstrap-tfstate.ps1
└── infra/
    ├── modules/
    │   ├── log-analytics/main.tf
    │   ├── container-registry/main.tf
    │   ├── key-vault/main.tf
    │   ├── sql-database/main.tf
    │   └── container-apps-environment/main.tf
    └── environments/
        ├── shared/   (backend.tf, main.tf, variables.tf, outputs.tf, terraform.tfvars.example)
        ├── dev/      (backend.tf ✅, main.tf ❌, variables.tf ❌, outputs.tf ❌, terraform.tfvars.example ❌)
        ├── staging/  (tutti da copiare)
        └── prod/     (tutti da copiare)
```
Nota: i contenuti di TUTTI questi file sono già stati generati nella
conversazione precedente su claude.ai e scaricati come file — vanno solo
posizionati nei path corretti sopra. Se non li ho già incollati nella
cartella, chiedimi di rigenerarli.

## Prossimi passi, in ordine
1. Completare la struttura di cartelle/file mancante come sopra
2. Sostituire il placeholder dello storage account in tutti i `backend.tf`
   rimasti (shared/staging/prod)
3. Creare i `terraform.tfvars` reali in shared/dev/staging/prod partendo
   dai rispettivi `.example`
4. `cd infra/environments/shared` → `terraform init && terraform validate
   && terraform plan` → rivedere il plan insieme prima di `apply` (crea
   solo Resource Group + ACR)
5. Stesso flusso su `dev` (crea Resource Group, Log Analytics, Key Vault,
   Azure SQL Server+Database serverless, Container Apps Environment —
   circa 7 risorse)
6. Solo dopo dev funzionante: applicazione .NET del microservizio
   `ticket-api` (CRUD ticket con EF Core), Dockerfile multi-stage
7. Configurazione OIDC GitHub Actions → Azure (Federated Credentials su
   Entra ID)
8. Pipeline Terraform (plan su PR con commento automatico, apply su
   merge, GitHub Environments con approvazioni per staging→prod)
9. Pipeline applicazione (build immagine, push su ACR, deploy su
   Container App)
10. Tagging/governance finale e naming convention CAF completa

## Cosa mi serve da Claude Code adesso
Aiutami a completare i file mancanti nella struttura sopra (posso
incollarteli io se li rigeneri, oppure recuperali dalla history se
disponibile), poi guidami passo passo su validate/plan/apply per
`shared` e `dev`, mantenendo per ogni risorsa lo stesso livello di
dettaglio (spiegazione + rilevanza AZ-305) usato finora.
