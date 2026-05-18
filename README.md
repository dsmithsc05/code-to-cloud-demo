# Stop Taxing Your Developers
## The Azure-Powered On-Ramp from Code to Cloud

> **Conference demo repository** · Code to Cloud Summit · Calgary, AB · 2026-05-24
> Consider Cloud with Derek

[![Deploy with azd](https://img.shields.io/badge/Deploy_with-azd-1A8FD4?style=for-the-badge)](https://aka.ms/azd)
[![Azure](https://img.shields.io/badge/Microsoft-Azure-0071BD?style=for-the-badge&logo=microsoftazure)](https://azure.microsoft.com)
[![.NET 8](https://img.shields.io/badge/.NET-8.0_LTS-512BD4?style=for-the-badge&logo=dotnet)](https://dotnet.microsoft.com)
[![Backstage](https://img.shields.io/badge/Backstage-CNCF-9BF0E1?style=for-the-badge)](https://backstage.io)
[![MIT](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

---

This repo is the full, runnable environment behind the talk **"Stop Taxing Your Developers: Building the Azure-Powered On-Ramp from Code to Cloud."** It walks through three demos showing how Platform Engineering with Azure-native tooling eliminates developer cognitive load — from a painful manual baseline all the way to a self-service Backstage portal.

If you saw the talk and want to fork this for your own platform: skip to [Quick Start](#quick-start). If you want to understand the demos: read [The Three Demos](#the-three-demos).

---

## Why this exists

Most "Platform Engineering" content stops at slides. This repo is the demo. Three concrete artifacts:

1. **Demo 1** — A scripted, recordable walkthrough of the 14-step manual cloud onboarding flow that every team has lived
2. **Demo 2** — `azd deploy` deploying a real .NET API to Azure in under 90 seconds, live on stage
3. **Demo 3** — Backstage on AKS, pre-seeded with 10 fictional fintech services, scaffolder template, mocked cost widget

You can run all three. Demo 1 you record yourself (script in `docs/demo1-script.md`). Demos 2 and 3 you can fork and run against your own subscription.

---

## The Three Demos

### Demo 1 — The Cognitive Tax (recorded, played as video)

A scripted walkthrough of what onboarding a single .NET microservice to Azure looks like **without** a platform: portal navigation, service principal creation, manual pipeline YAML, hand-wired Key Vault access policies, a deliberate RBAC scope error at step 11, and the 47-minute reveal that the app is still 500ing because of a misspelled env var.

📄 **Script:** [`docs/demo1-script.md`](docs/demo1-script.md) — 14 steps, exact commands, narrator lines, recording tips.

### Demo 2 — `azd deploy` in 90 seconds (live on stage)

Infrastructure pre-provisioned the morning of. On stage, a single `azd deploy` command:

- builds the multi-stage .NET 8 Docker image
- pushes to Azure Container Registry via user-assigned managed identity (no admin creds)
- updates the Container App revision with a blue/green swap
- end-to-end in 60–90 seconds

📄 **Runbook:** [`docs/demo2-runbook.md`](docs/demo2-runbook.md) — pre-provision steps, on-stage commands, fallback tree.

### Demo 3 — Backstage with Meridian Pay (live on stage)

Backstage running on AKS, pre-loaded with 10 fictional Meridian Pay services. Walkthrough: catalog browse, dependency graph, **mocked Azure Cost tab per service**, TechDocs, scaffolder template to create a brand-new .NET Azure service end-to-end (form → GitHub repo → catalog entry → first pipeline run) in ~90 seconds.

📄 **Script:** [`docs/demo3-script.md`](docs/demo3-script.md) — 8 steps, time budget, fallback tree.

---

## Repo Structure

```
code-to-cloud-demo/
├── azure.yaml                          # azd project manifest
├── catalog-info.yaml                   # Backstage catalog entry for this repo itself
├── .env.sample                         # Environment variables reference
├── .gitignore
├── LICENSE                             # MIT
│
├── apps/
│   └── sample-dotnet-api/
│       ├── src/
│       │   ├── Program.cs              # .NET 8 minimal API (/, /health, /healthz, /api/info)
│       │   ├── appsettings.json
│       │   ├── appsettings.Development.json
│       │   └── sample-dotnet-api.csproj
│       ├── tests/
│       │   ├── ApiTests.cs             # WebApplicationFactory integration tests
│       │   └── sample-dotnet-api.Tests.csproj
│       ├── Dockerfile                  # Multi-stage Alpine, non-root, ~110MB
│       └── .dockerignore
│
├── infra/
│   └── bicep/
│       ├── main.bicep                  # Subscription-scope orchestration
│       ├── modules/
│       │   ├── container-apps.bicep    # UAMI + ACR pull + Container App
│       │   ├── container-registry.bicep
│       │   ├── key-vault.bicep         # RBAC, soft delete, no purge protection (demo)
│       │   └── monitoring.bicep        # Log Analytics + Application Insights
│       └── parameters/
│           └── main.parameters.json
│
├── platform/
│   └── backstage/
│       ├── app-config/
│       │   ├── app-config.yaml         # Backstage main config (Microsoft auth, K8s, TechDocs)
│       │   └── app-config.production.yaml
│       ├── templates/
│       │   ├── new-dotnet-service.yaml # Scaffolder template
│       │   └── skeleton/               # Nunjucks-templated skeleton
│       └── plugins/
│           └── cost-widget/            # Mocked Azure Cost frontend plugin
│               ├── src/                # CostTab.tsx + api.ts + plugin.ts + index.ts
│               ├── fixtures/
│               │   └── mock-costs.json # 10 Meridian Pay services with 30-day trend
│               ├── package.json
│               ├── tsconfig.json
│               └── README.md
│
├── catalog/
│   └── meridian-pay/                   # 10 fictional fintech services + groups + users
│       ├── system.yaml                 # System: meridian-pay
│       ├── orgs.yaml                   # 5 Groups + 5 Users + parent BU
│       ├── payments-api/catalog-info.yaml
│       ├── ledger-svc/catalog-info.yaml
│       ├── fraud-detection/catalog-info.yaml
│       ├── statements-worker/catalog-info.yaml
│       ├── kyc-onboarding/catalog-info.yaml
│       ├── card-issuer-bridge/catalog-info.yaml
│       ├── merchant-portal/catalog-info.yaml
│       ├── webhook-dispatcher/catalog-info.yaml
│       ├── reconciliation-batch/catalog-info.yaml
│       └── audit-log-collector/catalog-info.yaml
│
├── .github/
│   └── workflows/
│       ├── azure-dev.yml               # azd provision + deploy on main
│       └── pr-validate.yml             # Bicep what-if + dotnet build/test/format
│
├── scripts/
│   ├── preprovision.sh                 # azd pre-flight checks
│   └── postprovision.sh                # Seed KV with example secrets
│
└── docs/
    ├── demo1-script.md                 # 14-step pain walkthrough (recordable)
    ├── demo2-runbook.md                # Stage-day azd deploy runbook
    └── demo3-script.md                 # Backstage walkthrough
```

---

## Quick Start

You forked this and want to run it against your own subscription.

### Prerequisites

```bash
# Install azd
winget install Microsoft.Azd                    # Windows
brew install azure/azd/azd                      # macOS
curl -fsSL https://aka.ms/install-azd.sh | bash # Linux

# Sign in
az login --tenant <YOUR_TENANT_ID>
azd auth login
```

### Run it

```bash
git clone https://github.com/dsmithsc05/code-to-cloud-demo
cd code-to-cloud-demo

# First-time setup — creates an azd environment file in .azure/
azd env new my-demo --location canadacentral

# Provision + deploy (this is azd up — for first-time users; ~4–6 min)
azd up
```

After it finishes:

```bash
curl $(azd env get-value SERVICE_API_URI)/health
# Expect: {"status":"healthy"}
```

### `azd up` vs `azd deploy` — which to use

| Command       | When                                                    | Time   |
|---------------|---------------------------------------------------------|--------|
| `azd up`      | First time, or after Bicep changes                      | 4–6m   |
| `azd provision` | Infra-only change                                     | 3–5m   |
| `azd deploy`  | App code change only (no Bicep change)                  | 60–90s |

**On stage, Derek runs `azd deploy` after pre-provisioning the morning of.** See [`docs/demo2-runbook.md`](docs/demo2-runbook.md).

### Teardown

```bash
azd down --purge --force
```

---

## Backstage Setup

The Backstage layer is independent of the .NET API and Bicep. It lives in `platform/backstage/`.

### Deploy Backstage to AKS

Use the [Backstage Helm chart](https://github.com/backstage/charts) with `app-config.yaml` from this repo mounted via ConfigMap. Required env vars (see `.env.sample`):

```bash
export AUTH_MICROSOFT_CLIENT_ID=<app-reg-client-id>
export AUTH_MICROSOFT_CLIENT_SECRET=<app-reg-secret>
export AUTH_MICROSOFT_TENANT_ID=<your-tenant-id>
export GITHUB_TOKEN=<personal-access-token-or-app-token>
export K8S_URL=<aks-api-server-url>
export K8S_SA_TOKEN=<service-account-token>
export POSTGRES_HOST=<your-postgres-host>
export POSTGRES_USER=backstage
export POSTGRES_PASSWORD=<password>
export POSTGRES_DB=backstage
```

### Pre-seed the catalog

The 10 Meridian Pay services + System + Groups + Users are registered as `file:` locations in `app-config.yaml`. Backstage discovers them automatically on startup. Verify with:

```bash
curl -s https://<backstage-url>/api/catalog/entities | jq 'length'
# Expect: 16+ entities (10 services + 1 system + 1 BU group + 5 team groups + 5 users)
```

### The cost widget plugin

`platform/backstage/plugins/cost-widget/` is a **frontend-only** Backstage plugin that adds an "Azure Cost" tab to every Component entity. It reads from a static JSON fixture (`fixtures/mock-costs.json`) right now. The backend integration with Azure Cost Management is in flight — see the plugin's [README](platform/backstage/plugins/cost-widget/README.md) for the swap path (~50 lines of `api.ts` plus a backend plugin against the Cost Management REST API).

To register the tab in your Backstage app:

```tsx
// packages/app/src/components/catalog/EntityPage.tsx
import { EntityCostTab } from '@meridianpay/plugin-cost-widget';

<EntityLayout.Route path="/cost" title="Azure Cost">
  <EntityCostTab />
</EntityLayout.Route>
```

---

## Meridian Pay catalog (fictional)

Used for Demo 3 realism. None of these services are real. The names, ownership, and architecture choices are designed to feel like a mid-sized fintech an architect in the audience might recognize.

| Service | Owner | Lifecycle | Language | Deploy target | Mock spend (CAD/mo) |
|---------|-------|-----------|----------|---------------|--------------------:|
| payments-api | team-payments | production | dotnet | Container Apps | $8,240 |
| ledger-svc | team-ledger | production | go | AKS | $6,180 |
| fraud-detection | team-risk | production | python | Container Apps | $5,720 |
| card-issuer-bridge | team-payments | production | dotnet | Container Apps | $4,650 |
| kyc-onboarding | team-risk | production | nodejs | Container Apps | $3,410 |
| webhook-dispatcher | team-payments | production | go | Container Apps | $2,890 |
| statements-worker | team-ledger | production | dotnet | Functions Premium | $1,940 |
| audit-log-collector | team-platform | production | dotnet | Functions Consumption | $1,615 |
| merchant-portal | team-merchant | production | typescript-react | Static Web Apps | $1,205 |
| reconciliation-batch | team-ledger | experimental | python | Container Apps Jobs | $980 |
| **Total** | | | | | **$36,830** |

---

## Environment Variables Reference

| Variable | Description | Required for |
|----------|-------------|--------------|
| `AZURE_SUBSCRIPTION_ID` | Target Azure subscription | azd |
| `AZURE_LOCATION` | Azure region (default `canadacentral`) | azd |
| `AZURE_ENV_NAME` | azd environment name | azd |
| `AZURE_TENANT_ID` | Entra ID tenant | azd, Backstage |
| `AZURE_RESOURCE_GROUP` | Auto-populated by azd | — |
| `AZURE_CONTAINER_REGISTRY_ENDPOINT` | Auto-populated by azd | — |
| `AZURE_KEY_VAULT_NAME` | Auto-populated by azd | — |
| `SERVICE_API_URI` | Auto-populated by azd post-provision | — |
| `AUTH_MICROSOFT_CLIENT_ID` | Backstage SSO app registration | Backstage |
| `AUTH_MICROSOFT_CLIENT_SECRET` | Backstage SSO secret | Backstage |
| `GITHUB_TOKEN` | Scaffolder publish-to-github | Backstage |
| `K8S_URL` | AKS API server URL | Backstage |
| `K8S_SA_TOKEN` | Backstage's read-only K8s service account token | Backstage |

See [`.env.sample`](.env.sample) for the full template.

---

## CI/CD

### On push to `main` — [`azure-dev.yml`](.github/workflows/azure-dev.yml)

1. Authenticate to Azure via federated OIDC (no stored client secret)
2. Build + test the .NET application
3. `azd provision --no-prompt` (idempotent — no-op if infra is current)
4. `azd deploy --no-prompt`
5. Write the deployed `SERVICE_API_URI` to the workflow summary

### On pull request — [`pr-validate.yml`](.github/workflows/pr-validate.yml)

1. `az bicep build` — syntax check
2. `az deployment sub what-if` — show what would change in infra
3. `dotnet restore`, `build`, `test`, `format --verify-no-changes`

### Required GitHub Secrets

| Secret | What |
|--------|------|
| `AZURE_CLIENT_ID` | App registration client ID (with federated credential for this repo) |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |
| `AZD_INITIAL_ENVIRONMENT_CONFIG` | Output of `azd env get-values` after first manual provision |

---

## Infrastructure overview

All Azure resources are provisioned via Bicep at subscription scope from `infra/bicep/main.bicep`.

```
Azure Subscription
└── Resource Group: rg-{env}
    ├── Log Analytics Workspace: law-{env}
    ├── Application Insights: appi-{env}            (Workspace-backed)
    ├── Container Registry: acr{env}                 (Standard, admin OFF)
    ├── Key Vault: kv-{hash}-{env}                   (RBAC enabled, soft delete 7d)
    ├── User-Assigned Managed Identity: id-api-{env} (AcrPull on ACR, KV Secrets User on KV)
    ├── Container Apps Environment: cae-{env}        (wired to Log Analytics)
    └── Container App: ca-api-{env}                  (UAMI-attached, ingress 8080, autoscale 1-3)
```

### Security posture

- **No admin credentials anywhere** — ACR uses managed identity AcrPull; KV uses RBAC, not access policies
- **OIDC for CI/CD** — federated credential on the app registration, no client secret in GitHub Secrets
- **Non-root container** — Dockerfile sets `USER app`
- **TLS-only ingress** — Container App `allowInsecure: false`
- **App Insights connection string** — passed as `@secure()` Bicep parameter, surfaced via env var, never logged
- **Key Vault soft delete enabled** — purge protection disabled for the demo, enable for prod

---

## Local development

```bash
cd apps/sample-dotnet-api/src
dotnet run
```

API available at `http://localhost:5000`.

| Endpoint     | Returns |
|--------------|---------|
| `GET /`      | Service info (name, version, status, timestamp, environment) |
| `GET /health`| `{"status":"healthy"}` |
| `GET /healthz` | ASP.NET health checks |
| `GET /api/info` | Region, instance, .NET version |
| `GET /swagger` | Swagger UI (Development only) |

### Running tests

```bash
cd apps/sample-dotnet-api
dotnet test tests/ --logger trx
```

---

## Audience resources

Scan the QR code on the closing slide for direct links to:

- This repository: [github.com/dsmithsc05/code-to-cloud-demo](https://github.com/dsmithsc05/code-to-cloud-demo)
- Azure Developer CLI docs: [aka.ms/azd](https://aka.ms/azd)
- Backstage on Azure: [learn.microsoft.com/azure/architecture](https://learn.microsoft.com/azure/architecture)
- Microsoft Platform Engineering: [learn.microsoft.com/platform-engineering](https://learn.microsoft.com/platform-engineering)
- CNCF Platform Engineering Maturity Model: [tag.cncf.io](https://tag.cncf.io)

---

## Speaker

**Derek** — Chief Architect of Cloud & Infrastructure / Cloud Evangelist
Consider Cloud with Derek

> Demystifying Azure, AI, and Platform Engineering for practitioners.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0071BD?style=flat&logo=linkedin)](https://linkedin.com)
[![YouTube](https://img.shields.io/badge/YouTube-Consider%20Cloud-FF0000?style=flat&logo=youtube)](https://youtube.com)

---

*Code to Cloud Summit · Calgary, AB · 2026-05-24*
