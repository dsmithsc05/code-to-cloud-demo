# Demo 2 — `azd deploy` in 90 Seconds

> **The money shot.** Single command. Pre-provisioned infra. 60–90 second live deploy on stage.

This runbook is what Derek follows day-of. Every command is literal. If anything in here looks off when you read it the morning of, **stop and fix it** — do not improvise on stage.

---

## Why `azd deploy` and not `azd up`

`azd up` does `provision` + `deploy` in one shot. On stage that takes 4–6 minutes — too long, and the early minutes are boring (creating empty resource groups). We provision the morning of, then on stage we run `azd deploy` only. That builds the image, pushes to ACR, and updates the Container App revision. 60–90s, fully visible, every second is interesting.

For audience members forking the repo, the README points them at `azd up` (first-time path). On stage we use `azd deploy` (incremental path).

---

## Morning of the talk — Pre-provision (do this once)

### 1. Sign in

```bash
az login --tenant <YOUR_TENANT_ID>
azd auth login
```

Confirm the right subscription is active:

```bash
az account show --query "{name:name, id:id}" -o table
```

Expected: subscription named for the demo (e.g. `ctc-demo-live`).

### 2. Create the azd environment

```bash
cd ~/code/code-to-cloud-demo
azd env new ctc-demo-live \
  --subscription <SUBSCRIPTION_ID> \
  --location canadacentral
```

This writes to `.azure/ctc-demo-live/.env`. Inspect it:

```bash
azd env get-values
```

Expected:
```
AZURE_ENV_NAME="ctc-demo-live"
AZURE_LOCATION="canadacentral"
AZURE_SUBSCRIPTION_ID="..."
```

### 3. Provision the infrastructure

```bash
azd provision --no-prompt
```

This runs the Bicep at subscription scope, creates:
- `rg-ctc-demo-live` resource group
- `law-ctc-demo-live` Log Analytics workspace
- `appi-ctc-demo-live` Application Insights
- `acrctcdemolive` Container Registry (Standard, admin OFF)
- `kv-{hash}-ctc-demo-live` Key Vault (RBAC enabled)
- `cae-ctc-demo-live` Container Apps environment
- `ca-api-ctc-demo-live` Container App (with the placeholder hello-world image)
- `id-api-ctc-demo-live` User-assigned managed identity, with AcrPull on the ACR and Key Vault Secrets User on the KV

**Expected duration:** 3–5 minutes total.

### 4. Confirm provisioning succeeded

```bash
az resource list --resource-group rg-ctc-demo-live -o table
```

Should show 8 resources. **Screenshot this output** and keep it in `~/Desktop/demo2-preflight-RG-screenshot.png` as your sanity reference.

### 5. Initial deploy to seed the Container App with a real image

```bash
azd deploy
```

This first deploy will be slower (no Docker layer cache, no warm ACR connection). Expected: 2–3 min. **This is fine — it's the pre-warm.** The on-stage deploy will be faster because layers cache.

### 6. Smoke test

```bash
curl -s $(azd env get-value SERVICE_API_URI) | jq
curl -s $(azd env get-value SERVICE_API_URI)/health | jq
curl -s $(azd env get-value SERVICE_API_URI)/api/info | jq
```

Expected: 200 from all three. The `/api/info` response should show `region: canadacentral`, the .NET version, and an instance ID.

---

## One hour before stage — Final smoke test

```bash
# 1. Confirm credentials still valid
azd auth login --check-status
az account show -o table

# 2. Confirm the Container App is healthy
curl -s -o /dev/null -w "%{http_code}\n" $(azd env get-value SERVICE_API_URI)/health
# Expect: 200

# 3. Touch the source so `azd deploy` actually has work to do on stage
# (otherwise the deploy is a no-op and finishes in 8 seconds — anticlimactic)
echo "// demo build $(date)" >> apps/sample-dotnet-api/src/Program.cs
git add -A && git commit -m "demo build marker"
# Do NOT push yet.

# 4. Verify Docker is running
docker ps
docker info | grep -i version

# 5. Final azd deploy dry-run hint (no actual flag — just rehearse the command)
echo "azd deploy" | xclip -selection clipboard  # or pbcopy on macOS
```

**After this point: no code changes. No `git push`. Hands off the keyboard until you walk on stage.**

---

## On stage — The 90-second window

### Pre-roll (while the slide is still up)

Terminal is already open, working directory is the repo root, `azd env get-values` confirms `ctc-demo-live` is active.

### The single command

```bash
azd deploy
```

### Expected output trace

```
Packaging services (azd)

  (✓) Done: Packaging service api

Deploying services (azd)

  (✓) Done: Deploying service api
      - Endpoint: https://ca-api-ctc-demo-live.<env>.canadacentral.azurecontainerapps.io/

SUCCESS: Your application was deployed to Azure in 1m12s.
You can view the resources created under the resource group rg-ctc-demo-live in Azure Portal:
https://portal.azure.com/#@/resource/subscriptions/<sub>/resourceGroups/rg-ctc-demo-live/overview
```

### Talking points by elapsed time

| Time   | What's happening on screen        | What Derek says |
|--------|------------------------------------|-----------------|
| 0–15s  | "Packaging service api"            | "azd is packaging the .NET app — multi-stage Docker build, the layer cache means this is really just the publish step." |
| 15–45s | Build output scrolling, ACR push   | "Now it's pushing to ACR — note: no docker login, no admin password, no AZURE_CREDENTIALS secret. It's using the federated identity I set up at provision time." |
| 45–75s | "Updating Container App revision"  | "Container Apps is doing a blue-green revision swap under the hood. Traffic flips 100% to the new revision the moment the health probe passes." |
| 75–90s | "SUCCESS: Your application was deployed…" | "And that's it. From `git commit` to running in Azure — autoscale, TLS, App Insights, Key Vault — fourteen steps collapsed into one." |

### Immediately after — show the new revision is live

```bash
curl -s $(azd env get-value SERVICE_API_URI)/api/info | jq
```

Expected: 200, with a new build timestamp matching the change you made in pre-flight step 3.

Then click into the portal blade you have pre-loaded:
- Container App revisions tab — show the two revisions, traffic 0/100
- Application Insights live metrics — show requests flowing through

---

## If something breaks — fallback tree

**The cardinal rule: never apologize on stage. Switch to the fallback recording and keep talking.**

| Symptom | First action | Second action |
|---------|--------------|---------------|
| `azd deploy` hangs > 30s on "Packaging" | Ctrl+C, run `docker build apps/sample-dotnet-api/` in another tab, see the error | Switch to `docs/demo2-fallback.mp4` |
| ACR push fails with auth error | `az acr login -n acrctcdemolive` in another tab, then retry `azd deploy` | Switch to fallback |
| Container App revision not activating | `az containerapp revision list -n ca-api-ctc-demo-live -g rg-ctc-demo-live -o table` to see why | Switch to fallback |
| Venue Wi-Fi drops | Switch to fallback immediately. Don't wait. | n/a |
| `curl` returns 500 after deploy | App Insights → Failures blade → root cause is almost certainly an env var. Skip the curl, go straight to portal. | Show the App Insights live metrics instead — equally compelling |

### Where the fallback recording lives

```
docs/demo2-fallback.mp4    (record this morning-of, OBS, full 90 sec live deploy)
```

Recommended: record three takes morning of. Keep the cleanest one as `demo2-fallback.mp4`. The other two as backup.

---

## Post-demo — what audience members can do

This is the moment to point at the QR code on screen:

```bash
git clone https://github.com/dsmithsc05/code-to-cloud-demo
cd code-to-cloud-demo
azd auth login
azd env new my-demo --location canadacentral
azd up
```

Their first `azd up` will take 4–6 min (no pre-provision). Mention this so they don't think their fork is broken.

---

## Teardown — after the talk

```bash
azd down --purge --force
```

`--purge` cleans up Key Vault soft-deleted state. `--force` skips the "are you sure" prompt. Total teardown: ~5 min. Run it from the hotel after the talk.
