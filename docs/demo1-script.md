# Demo 1 — The Cognitive Tax

> **14 steps to deploy ONE microservice without a platform.**
> Recording target: 9–10 min raw → edit to 90 sec at 1.5× speed with cuts and zooms.

This is the script Derek follows while recording. Every command and click path is literal. The deliberate RBAC scope error at step 11 is the emotional anchor — that's the moment the audience recognizes their own week.

---

## Setup (do once, before you hit record)

- [ ] Fresh Azure subscription named **CCWD-Sub-Demo1** with nothing in it
- [ ] Terminal at 16pt font, dark theme, single window (Windows Terminal or iTerm)
- [ ] Edge browser, logged into `portal.azure.com` as the subscription owner
- [ ] VS Code with an empty repo open in a workspace folder
- [ ] Notepad open in the corner (you'll need it for credential paste shame)
- [ ] Wall clock visible in OBS overlay so viewers see real time pass
- [ ] OBS recording at 1080p60, mic gain checked, headphones on
- [ ] **Sub ID copied to clipboard** before you start — refer to it as `$SUB`

> **Cut rule for editing:** every portal load > 4 seconds gets compressed to a 0.3s blur transition. Keep step 11 as one continuous unbroken take.

---

## The 14 Steps

### Step 1 — Open the portal, find the subscription          [Target: 25s]

🎙️ **Narration:** "Okay. New service. Container Apps target. I open the portal because I have to — that's where the resource group lives."

🖥️ **Action:** Navigate `portal.azure.com` → **Subscriptions** → click `CCWD-Sub-Demo1`.

📋 **Screen:** Subscription blade. Empty resource list.

⏱️ **Why this hurts:** Three clicks before I've done anything useful. The portal is the first tax.

---

### Step 2 — Create the resource group                       [Target: 40s]

🎙️ **Narration:** "Resource group. Has to be regional. Canada Central — that's our standard. Tag it… let's pretend we have a tag policy."

🖥️ **Action:** **Resource groups** → **+ Create** → Name `rg-pain-demo` → Region `Canada Central` → Tags `env=demo`, `owner=derek` → **Review + create** → **Create**.

📋 **Screen:** Green checkmark. "Your deployment is complete."

⏱️ **Why this hurts:** I clicked through a wizard to put a label on a folder.

---

### Step 3 — Create a service principal via CLI              [Target: 35s]

🎙️ **Narration:** "Pipeline needs an identity. I'll create a service principal. Scoped to the RG, contributor role. I'll figure out RBAC tightening later. (Spoiler: I won't.)"

🖥️ **Action:** Switch to terminal.
```bash
az ad sp create-for-rbac \
  --name "sp-pain-demo" \
  --role Contributor \
  --scopes /subscriptions/$SUB/resourceGroups/rg-pain-demo \
  --sdk-auth
```

📋 **Screen:** JSON blob with `clientId`, `clientSecret`, `tenantId`, `subscriptionId`. The secret is visible. Of course it is.

⏱️ **Why this hurts:** I just printed a secret to my terminal scrollback. Where does that scrollback live? When does it get rotated? I don't know.

---

### Step 4 — Copy the credential JSON to Notepad             [Target: 20s]

🎙️ **Narration:** "And now I have to move that into GitHub Secrets, and the only way I know how is… select, copy, paste into Notepad, then paste into Secrets. I'll close the file after. Probably. Maybe."

🖥️ **Action:** Highlight the JSON in terminal → Ctrl+C → switch to Notepad → Ctrl+V. Sit there for a beat.

📋 **Screen:** Notepad window with the secret in plain text.

⏱️ **Why this hurts:** Every senior engineer in this room just felt their stomach drop. This is how creds end up in screenshots, in Slack, in `~/Desktop/temp.txt`.

---

### Step 5 — Wire up GitHub Secrets                          [Target: 40s]

🎙️ **Narration:** "Over to GitHub. New repo, blank. Settings, Secrets and variables, Actions, New repository secret. Name it AZURE_CREDENTIALS — that's the convention nobody documents but everybody uses."

🖥️ **Action:** GitHub.com → `dsmithsc05/ctc-pain-demo` → **Settings** → **Secrets and variables** → **Actions** → **New repository secret** → Name `AZURE_CREDENTIALS` → paste the JSON from Notepad → **Add secret**.

📋 **Screen:** Secret listed, value hidden.

⏱️ **Why this hurts:** The secret name is a folk tradition. No schema. No validation. Get the name wrong, your pipeline fails with `Login failed` in a way that takes 20 minutes to diagnose.

---

### Step 6 — Write the Dockerfile and hand-craft the workflow YAML    [Target: 75s]

🎙️ **Narration:** "Two things I need before I can ship: a Dockerfile and a pipeline. My Dockerfile is already sitting next to the source — that's the easy part. The pipeline is where it gets painful. I'll grab a template from the Actions marketplace, paste it in, and start tweaking. Watch how many times I have to type the resource group name."

🖥️ **Action (part a):** VS Code → open `apps/sample-dotnet-api/Dockerfile`. This is the multi-stage .NET 8 Alpine image that lives next to the source code:

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
WORKDIR /source

COPY src/sample-dotnet-api.csproj src/
RUN dotnet restore src/sample-dotnet-api.csproj

COPY src/ src/
RUN dotnet publish src/sample-dotnet-api.csproj \
    -c Release \
    -o /app/publish \
    --no-restore \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "sample-dotnet-api.dll"]
```

🖥️ **Action (part b):** VS Code → create `.github/workflows/deploy.yml`. Paste this. The resource group name `rg-paindemo` is deliberately misspelled (missing the hyphen) and appears in **three** places:

```yaml
name: Deploy
on: { push: { branches: [main] } }
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - name: Verify resource group
        run: az group show --name rg-paindemo
      - name: Build image
        run: |
          docker build \
            -t pain-demo:${{ github.sha }} \
            -f apps/sample-dotnet-api/Dockerfile \
            apps/sample-dotnet-api/
      - name: Push to ACR
        run: |
          az acr login -n acrpaindemo
          docker tag pain-demo:${{ github.sha }} acrpaindemo.azurecr.io/pain-demo:${{ github.sha }}
          docker push acrpaindemo.azurecr.io/pain-demo:${{ github.sha }}
      - name: Create Container App Environment
        run: |
          az containerapp env create \
            --name cae-pain-demo \
            --resource-group rg-paindemo \
            --location canadacentral 2>/dev/null || true
      - name: Deploy to Container Apps
        run: |
          az containerapp create \
            --name ca-pain-demo \
            --resource-group rg-paindemo \
            --environment cae-pain-demo \
            --image acrpaindemo.azurecr.io/pain-demo:${{ github.sha }} \
            --registry-server acrpaindemo.azurecr.io \
            --min-replicas 1 \
            --target-port 8080 \
            --ingress external \
            --secrets "api-greeting=keyvaultref:https://kv-pain-demo.vault.azure.net/secrets/api-greeting,identityref:system" \
            --env-vars "api-greeting=secretref:api-greeting"
```

> ⚠️ **Demo note — two deliberate bugs:**
> 1. `rg-paindemo` (missing hyphen) appears in `az group show`, `containerapp env create`, and `containerapp create`. This triggers `ResourceGroupNotFound` in Step 7.
> 2. `--env-vars "api-greeting=secretref:api-greeting"` injects the secret under the env var name `api-greeting`, but the app reads `GREETING_TEXT`. This mismatch is what causes the 500 in Step 14.

Commit, push.

📋 **Screen:** GitHub repo, file committed.

⏱️ **Why this hurts:** The Dockerfile path has to match the build context. The RG name has to be consistent across three commands. One fat-finger anywhere and the whole thing dies silently two steps later.

---

### Step 7 — First run fails: resource group not found       [Target: 25s]

🎙️ **Narration:** "And here we go. Pipeline runs. Verify resource group step. (pause) Resource group 'rg-paindemo' could not be found. Of course. I typed it wrong. Three times."

🖥️ **Action:** GitHub Actions tab → click the running workflow → expand the **Verify resource group** step.

📋 **Screen:** Red X. Error: `(ResourceGroupNotFound) Resource group 'rg-paindemo' could not be found.`

⏱️ **Why this hurts:** The error is clear *now*. It's not clear at 11pm on a Tuesday.

---

### Step 8 — Fix the typo, push, re-run                      [Target: 30s]

🎙️ **Narration:** "Fix the hyphen — in all four places. Push. Wait. (sits and waits)"

🖥️ **Action:** Edit YAML, change every `rg-paindemo` to `rg-pain-demo` → `git commit -am "fix rg name" && git push`. Watch the workflow run.

📋 **Screen:** Workflow re-running. **Verify resource group** passes. **Build image** step succeeds. **Push to ACR** step now fails: `ERROR: Get "https://acrpaindemo.azurecr.io/v2/": dial tcp: no such host — registry 'acrpaindemo' not found`.

⏱️ **Why this hurts:** I haven't even *created* the ACR yet. Why would I have? The docs I copied from assumed it existed.

---

### Step 9 — Realize I need ACR                              [Target: 15s]

🎙️ **Narration:** "Right. Container Registry. Forgot. It's not in the resource group because I didn't put it there."

🖥️ **Action:** Brief shrug. Switch back to the portal.

⏱️ **Why this hurts:** Mental model break. I was in pipeline-land. Now I have to context-switch to infra-land.

---

### Step 10 — Create ACR via the portal                      [Target: 60s]

🎙️ **Narration:** "Container Registries, Create. Name acrpaindemo — globally unique, please don't be taken. Standard tier. Canada Central. Wait sixty seconds for the resource to come up."

🖥️ **Action:** Portal → **Container Registries** → **+ Create** → Subscription `CCWD-Sub-Demo1`, RG `rg-pain-demo`, Name `acrpaindemo`, Location `Canada Central`, SKU `Standard` → **Review + create** → **Create** → wait.

📋 **Screen:** Deployment progress bar. Spins for ~50s. Eventually green.

⏱️ **Why this hurts:** Sixty seconds of nothing. Nobody clicks away during a demo; in real life, this is when you check Slack and lose the thread.

---

### Step 11 — THE DELIBERATE RBAC SCOPE ERROR                [Target: 90s — KEEP UNBROKEN]

🎙️ **Narration:** "Now the service principal needs to push to ACR. AcrPush role. I'll grant it… (long pause, looks at terminal) …at the subscription level. (pause) I know. I know. Don't do this in prod. But it's 11:47 PM and I just want this thing to deploy. This is the cognitive tax. This is exactly the kind of thing that ends up in your CSPM dashboard at 2 AM on a Saturday."

🖥️ **Action:** Terminal.
```bash
# What I should do — scoped to the ACR resource:
# az role assignment create \
#   --role AcrPush \
#   --assignee <sp-app-id> \
#   --scope /subscriptions/$SUB/resourceGroups/rg-pain-demo/providers/Microsoft.ContainerRegistry/registries/acrpaindemo

# What I actually do because I'm tired:
az role assignment create \
  --role AcrPush \
  --assignee <sp-app-id-from-step-3> \
  --scope /subscriptions/$SUB
```

📋 **Screen:** JSON output. Role assignment created at subscription scope.

⏱️ **Why this hurts:** I just gave one service principal AcrPush on every container registry in the subscription, present and future. The pipeline will work. The security team will not be happy.

> 🎬 **Recording note:** This is the anchor moment. Keep it as one unbroken shot. Don't cut. Let the silence after "Don't do this in prod" land.

---

### Step 12 — Re-run, now it fails on Key Vault              [Target: 50s]

🎙️ **Narration:** "Push again. Build's cached, ACR push works, Container App Environment creates fine… and then the deploy step dies. Why? The `az containerapp create` command tries to wire up the Key Vault secret reference — and Key Vault `kv-pain-demo` doesn't exist yet. Nobody told me I needed one — until the pipeline told me."

🖥️ **Action:** GitHub Actions logs → expand **Deploy to Container Apps** step → see:

```
ERROR: (SecretInvalidValue) Secret 'api-greeting': Key Vault 'kv-pain-demo' was not found.
       The key vault secret reference could not be resolved.
```

Switch to portal → **Key Vaults** → **+ Create** → Name `kv-pain-demo` → Region `Canada Central` → **Access policy** (NOT RBAC, because the doc that came up first said access policies) → set get/list secrets permission for `sp-pain-demo` → Create. Also assign the Container App's system-managed identity the `Key Vault Secrets User` role — or try to, and realize managed identity wasn't enabled, and go fix that too.

📋 **Screen:** KV created. Access policy granted. Managed identity enabled on the Container App.

⏱️ **Why this hurts:** Access policies vs RBAC is the most confusing thing in the Azure security model. I picked wrong. I still won't know until audit.

---

### Step 13 — Add the secret, trigger re-deploy              [Target: 45s]

🎙️ **Narration:** "Add the secret. The pipeline already has the Key Vault reference wired — I put that in when I first wrote it. I just need the Key Vault to actually have the value. Push an empty commit to kick the workflow."

🖥️ **Action:**
```bash
az keyvault secret set --vault-name kv-pain-demo --name api-greeting --value "hello"
git commit --allow-empty -m "trigger redeploy after kv setup" && git push
```

📋 **Screen:** Workflow runs. All steps pass — Verify, Build, Push, Env create (already exists, `|| true` swallows it), Deploy succeeds. Container App is live. FQDN appears in the deploy output.

---

### Step 14 — Open the URL. The app is 500ing.               [Target: 60s]

🎙️ **Narration:** "Click the FQDN, hit `/greeting`. (waits) Five hundred. (long pause) Logs."

🖥️ **Action:**
```bash
curl https://<fqdn-from-deploy-output>/greeting
# → HTTP 500 Internal Server Error
```

Portal → Container App → **Logs** → KQL query the last 5 min:
```kusto
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(5m)
| where Log_s contains "GREETING_TEXT"
| project TimeGenerated, Log_s
```

Find: `System.InvalidOperationException: GREETING_TEXT was null`. The pipeline injects the secret as env var `api-greeting` (line `--env-vars "api-greeting=secretref:api-greeting"`). The app's `/greeting` endpoint reads `GREETING_TEXT`. Different name. App throws. 500.

🎙️ **Narration:** "Forty-seven minutes. The app is deployed. The app is broken. The variable name is wrong. Every team in this room has lived this week."

📋 **Screen:** `curl` output showing `500 Internal Server Error`. Wall clock visible: started at 11:00, now 11:47.

⏱️ **Why this hurts:** It's not one big thing. It's fourteen small things. Each one alone is fine. Together they're the tax.

---

## Closing transition (record separately)

🎬 **Cut to black. 1.5 seconds.**

🎬 **Camera back on Derek's face.** "Now watch this."

🎬 **Cut to Demo 2 start screen.**

---

## Editing notes

- **Run time targets:** raw 9–10 min, final cut 90 sec at 1.5×
- **Compress hard:** portal loads, az command spinners — blur transitions
- **Keep at full speed:** Step 11 (the RBAC error), Step 14 (the 500 reveal)
- **Add lower-third captions** at each step: "Step N — what's happening"
- **Wall clock overlay** the entire time — viewers should see the minutes accumulate
- **Final frame before cut:** zoom in on the wall clock showing 11:47
- **Audio:** ambient room noise is fine. Don't over-produce — it should feel real.

---

## Why this script works for the talk

The 14 steps aren't a strawman. Every one maps to a real cognitive load:
1–2: portal navigation tax
3–5: credential handling tax
6–9: pipeline-YAML-as-code tax with no validation
10: missing-resource tax
**11: the security-shortcut tax** ← the moment of recognition
12–13: hidden-dependency tax (RBAC vs access policies)
14: config-mismatch tax

Demo 2 collapses all 14 into one command. That's the punchline.
