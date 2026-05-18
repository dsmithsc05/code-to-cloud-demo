# Demo 3 — Backstage with Meridian Pay

> **The self-service developer portal demo.** 8 steps. ~3 minutes live. Backstage on AKS, pre-seeded with 10 fictional fintech services.

This is what Derek walks the audience through after Demo 2 lands. The moment that matters is **step 4** — the cost widget. Engineering managers in the audience lean forward at that one.

---

## Pre-flight (before stage)

- [ ] Backstage running at `https://backstage.demo.considercloud.local` (or `kubectl port-forward svc/backstage 3000:80 -n backstage` as fallback)
- [ ] AKS cluster `aks-meridian-prod` healthy: `kubectl get nodes` returns 3 nodes Ready
- [ ] Catalog populated with all 10 Meridian Pay services + 5 groups + 5 users + the System entity (run `cd platform/backstage && yarn catalog:refresh` if anything is missing)
- [ ] Logged into Backstage via Entra ID SSO — confirm your user displays as `Derek` in the top right
- [ ] **Second browser tab pre-opened** at `https://github.com/meridianpay/loyalty-points-api/actions` (the new service we're going to create — won't exist yet, but the URL is parked so we can refresh it the moment the scaffolder finishes)
- [ ] Cost widget plugin enabled — open `payments-api`, click Azure Cost tab, confirm it renders the $8,240/mo card. If it doesn't, the fixture file path is wrong; check `platform/backstage/plugins/cost-widget/fixtures/mock-costs.json` exists and `app-config.yaml` `costWidget.dataSource` points at it.
- [ ] Browser zoom set to 110% so the back row can read service names

---

## The 8-step walkthrough

### Step 1 — Open the catalog                                [~15s]

🎙️ **Narration:** "This is the portal every Meridian engineer opens on day one. Catalog of services, owned, indexed, searchable."

🖥️ **Action:** Backstage home → **Catalog** in left nav. Default view: Components, owned by my groups (toggle off so all 10 are visible).

📋 **What the audience sees:** Table with 10 services. Columns: Name, System (all `meridian-pay`), Owner (team-payments, team-ledger, team-risk, etc.), Lifecycle, Type.

🎯 **Goal:** Audience absorbs "this looks like a real platform."

---

### Step 2 — Filter by owner                                 [~15s]

🎙️ **Narration:** "Discoverability without asking. Every service has an owner. If I want to know what the payments team runs—"

🖥️ **Action:** Click **Owner** filter in left sidebar → check `team-payments`. Catalog filters to 3 services: `payments-api`, `card-issuer-bridge`, `webhook-dispatcher`.

📋 **What the audience sees:** Live filter. Three services remain.

🎯 **Goal:** "Backstage replaces the 'who owns this thing' Slack thread."

---

### Step 3 — Open `payments-api`                             [~25s]

🎙️ **Narration:** "Let me click into payments-api. Overview tab — owner, lifecycle, repo link, and the dependency graph."

🖥️ **Action:** Click `payments-api` row. Default **Overview** tab loads.

📋 **What the audience sees:**
- About card: owner Payments, lifecycle production, tags dotnet/container-apps
- Links: Source code (GitHub), PagerDuty
- **Relations graph** showing `payments-api` → depends on → `ledger-svc`, `fraud-detection`, `azure-key-vault`

🎯 **Goal:** "This is what 'I'm on call and this service is broken' looks like — I know who owns it, what it depends on, and where to page."

---

### Step 4 — Click the Azure Cost tab                       [~30s] ★ THE MOMENT ★

🎙️ **Narration:** "Now the tab the engineering managers in this room have been waiting for. (clicks Azure Cost)"

🖥️ **Action:** Click **Azure Cost** tab in the entity tabs row.

📋 **What the audience sees:**
- Big number: **$8,240 / month** CAD
- 30-day sparkline showing slight upward trend
- Top resources table: `ca-api-payments-prod` $5,120, `appi-payments-prod` $1,840, `kv-payments-prod` $1,280
- Subtle "Beta · mocked data" chip in the corner

🎙️ **Narration (this part matters — be honest):** "Per-service spend, surfaced where the engineer already is. Two notes. One: the backend integration with Azure Cost Management is in flight — what you're seeing is the frontend wired to a mock fixture in the repo. I wanted to show the experience. Two: this is the wedge. Once cost is visible per service, owned by a team, engineering managers can have informed conversations about right-sizing. That's the whole point of putting it here."

🎯 **Goal:** Engineering managers in the audience visibly nod. This is the slide they'll screenshot.

---

### Step 5 — TechDocs tab                                    [~20s]

🎙️ **Narration:** "TechDocs. Auto-generated from the repo's README and docs folder. Search across all services, not per repo."

🖥️ **Action:** Click **Docs** tab. Show the rendered README — title, sections, architecture diagram if you embedded one.

📋 **What the audience sees:** Real docs, rendered inline, indexed by Backstage search.

🎯 **Goal:** "Documentation lives next to the service, not in a wiki nobody updates."

---

### Step 6 — Click "Create" in top nav                       [~15s]

🎙️ **Narration:** "Now the other half — self-service. Create. Templates."

🖥️ **Action:** Click **Create...** in the top nav bar.

📋 **What the audience sees:** Template gallery. ".NET Azure Service" template tile with `dotnet`, `azure`, `recommended` tags.

🎯 **Goal:** Set up the scaffolder reveal.

---

### Step 7 — Fill the form, submit                          [~40s]

🎙️ **Narration:** "Brand new service. Let's say we're launching a loyalty points feature."

🖥️ **Action:** Click the **.NET Azure Service** template → **Choose**.

Fill the 3-step form:
- **Service Details:**
  - Name: `loyalty-points-api`
  - Description: `Earn, redeem, and expire loyalty points for cardholders`
  - Owner: `team-payments`
- **Azure Configuration:**
  - Environment: `dev`
  - Region: `canadacentral`
- **Repository:**
  - Repo URL: `github.com?owner=meridianpay&repo=loyalty-points-api`

Click **Review** → **Create**.

📋 **What the audience sees:** Scaffolder progress. Three steps animate:
1. ✓ Fetch Template (0.8s)
2. ✓ Publish to GitHub (3s)
3. ✓ Register in Catalog (1s)

🎯 **Goal:** Audience watches a new service materialize. Real GitHub repo. Real catalog entry.

---

### Step 8 — Open in Catalog + show the pipeline running    [~40s]

🎙️ **Narration:** "Open in Catalog. There it is — new service, owner, lifecycle dev. And in the other tab—"

🖥️ **Action:**
1. Click **Open in Catalog** in the scaffolder output. Backstage navigates to the new `loyalty-points-api` entity.
2. Switch to the pre-opened GitHub Actions tab. Refresh. The first workflow run is already in progress (the skeleton repo's `azure-dev.yml` triggered on initial commit).

📋 **What the audience sees:**
- New service in Backstage catalog with all annotations populated
- GitHub Actions workflow running its first build — green check on `dotnet build`, in progress on `azd provision`

🎙️ **Narration (closer):** "Idea to running service: about ninety seconds. Self-service. The platform team didn't have to do anything. That's the on-ramp. From code to cloud. Without taxing the developer."

🎯 **Goal:** Audience claps. Or at least nods harder.

---

## If something breaks — fallback tree

| Symptom | What to do |
|---------|------------|
| Backstage returns 500 on catalog page | Switch to `docs/demo3-fallback.mp4`. Narrate over it. |
| Cost widget shows "No cost data" | Open dev tools, you'll see a 404 on the fixture URL. Continue past it; mention "the cost widget is a plugin in the repo, you can see it there." |
| Scaffolder fails on **Publish to GitHub** | Most likely cause: `GITHUB_TOKEN` env var expired. Say "GitHub auth blip — let me show you what it looks like when it works" and switch to fallback. |
| Scaffolder fails on **Register in Catalog** | The repo exists on GitHub but didn't catalog. Manual fallback: `curl -X POST $BACKSTAGE_BACKEND_BASE_URL/api/catalog/locations -d '...'`. Skip it on stage; just show the new repo on GitHub. |
| Entra SSO redirects to login mid-demo | Token expired. Have the password manager ready, log in, continue. **Practice this once** so it's smooth. |
| Anything else | Switch to fallback. Keep talking. Do not show errors on the projector. |

---

## Resources for audience

When you wrap, point at the QR slide:

- Catalog YAMLs for all 10 Meridian Pay services: `catalog/meridian-pay/` in this repo
- The scaffolder template + skeleton: `platform/backstage/templates/`
- The cost widget plugin (frontend only, backend in flight): `platform/backstage/plugins/cost-widget/`
- Backstage on AKS deployment notes: `docs/backstage-on-aks.md` (TODO write this if time permits before talk)
- Microsoft Platform Engineering guidance: `aka.ms/platform-engineering`

---

## Time budget

| Step | Target | Cumulative |
|------|-------:|-----------:|
| 1. Open catalog | 15s | 0:15 |
| 2. Filter by owner | 15s | 0:30 |
| 3. Open payments-api | 25s | 0:55 |
| **4. Cost tab** | **30s** | **1:25** |
| 5. TechDocs tab | 20s | 1:45 |
| 6. Click Create | 15s | 2:00 |
| 7. Fill template form | 40s | 2:40 |
| 8. Show catalog + pipeline | 40s | 3:20 |

Total: ~3:20. If you're running long, drop the TechDocs tab (step 5). If you're running short, hover the dependency graph in step 3 for an extra 15s.
