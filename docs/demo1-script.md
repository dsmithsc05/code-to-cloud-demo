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

### Step 6 — Hand-craft the workflow YAML                    [Target: 60s]

🎙️ **Narration:** "Now the pipeline. I'll grab a starter from the GitHub Actions marketplace, paste it in, and tweak. Look — I'm going to type the resource group name in three places. Watch."

🖥️ **Action:** VS Code → create `.github/workflows/deploy.yml`. Paste this (it's deliberately wrong on line 21):

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
      - name: Build image
        run: docker build -t pain-demo:${{ github.sha }} .
      - name: Push to ACR
        run: |
          az acr login -n acrpaindemo
          docker tag pain-demo:${{ github.sha }} acrpaindemo.azurecr.io/pain-demo:${{ github.sha }}
          docker push acrpaindemo.azurecr.io/pain-demo:${{ github.sha }}
      - name: Deploy
        run: |
          az containerapp update \
            -n ca-pain-demo \
            -g rg-paindemo \   # <-- TYPO: should be rg-pain-demo
            --image acrpaindemo.azurecr.io/pain-demo:${{ github.sha }}
```

Commit, push.

📋 **Screen:** GitHub repo, file committed.

⏱️ **Why this hurts:** Three opportunities to fat-finger the RG name. One typo. Hours of debugging.

---

### Step 7 — First run fails: resource group not found       [Target: 25s]

🎙️ **Narration:** "And here we go. Pipeline runs. Container Apps update step. (pause) Resource group 'rg-paindemo' not found. Of course."

🖥️ **Action:** GitHub Actions tab → click the running workflow → expand the failing step.

📋 **Screen:** Red X. Error: `ResourceGroupNotFound: Resource group 'rg-paindemo' could not be found.`

⏱️ **Why this hurts:** The error is clear *now*. It's not clear at 11pm on a Tuesday.

---

### Step 8 — Fix the typo, push, re-run                      [Target: 30s]

🎙️ **Narration:** "Fix the hyphen. Push. Wait. (sits and waits)"

🖥️ **Action:** Edit YAML, change `rg-paindemo` to `rg-pain-demo` → `git commit -am "fix rg name" && git push`. Watch the workflow run.

📋 **Screen:** Workflow re-running. Build step succeeds. **Push to ACR** step now fails: `Error: az acr login failed: registry 'acrpaindemo' not found`.

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

### Step 12 — Re-run, now it hangs on Key Vault              [Target: 50s]

🎙️ **Narration:** "Push again. Build's cached now, ACR push works, deploy step runs… and the app starts, and immediately crashes on startup. Why? It can't read its config from Key Vault. Because the Key Vault doesn't exist yet. Because nobody told me I needed one — until the app crashed."

🖥️ **Action:** GitHub Actions logs → expand container startup logs → see `KeyVaultErrorException: The user, group or application 'sp-pain-demo' does not have secrets get permission on key vault 'kv-pain-demo'.`

Switch to portal → **Key Vaults** → **+ Create** → Name `kv-pain-demo` → Region `Canada Central` → **Access policy** (NOT RBAC, because the doc that came up first said access policies) → set get/list secrets permission for `sp-pain-demo` → Create.

📋 **Screen:** KV created. Access policy granted.

⏱️ **Why this hurts:** Access policies vs RBAC is the most confusing thing in the Azure security model. I picked wrong. I won't know until audit.

---

### Step 13 — Add the secret, update YAML to read it         [Target: 45s]

🎙️ **Narration:** "Add the secret. Update the pipeline to inject it. Push. Wait."

🖥️ **Action:**
```bash
az keyvault secret set --vault-name kv-pain-demo --name api-greeting --value "hello"
```
Edit `deploy.yml` to add `--secrets api-greeting=keyvaultref:https://kv-pain-demo.vault.azure.net/secrets/api-greeting,identityref:system` to the `containerapp update`. Commit, push.

📋 **Screen:** Workflow runs, deploy step succeeds (15s).

---

### Step 14 — Open the URL. The app is 500ing.               [Target: 60s]

🎙️ **Narration:** "Click the FQDN. (waits) Five hundred. (long pause) Logs."

🖥️ **Action:** Portal → Container App → **Logs** → query the last 5 min. Find: `System.NullReferenceException: GREETING_TEXT was null`. Pipeline injected the secret as `api-greeting`, the app reads `GREETING_TEXT`. Casing + name mismatch.

🎙️ **Narration:** "Forty-seven minutes. The app is deployed. The app is broken. The variable name is wrong. Every team in this room has lived this week."

📋 **Screen:** App still showing 500. Wall clock visible: started at 11:00, now 11:47.

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
