# cost-widget

Backstage plugin that adds an **Azure Cost** tab to every Component entity.

## What it shows

- Estimated monthly Azure spend in CAD
- 30-day spend trend (inline SVG sparkline, no chart library)
- Top 3 resources contributing to the spend

## Current state (May 2026)

**Frontend only — backend integration in flight.**

The frontend reads from a JSON fixture at `fixtures/mock-costs.json`. To swap
for a real backend integration with Azure Cost Management:

1. Replace `loadCostFixture` in `src/api.ts` with a call to the backend plugin
   (`/api/cost-widget/services/<serviceId>`).
2. Implement the backend plugin against the Azure Cost Management REST API
   (`https://management.azure.com/.../providers/Microsoft.CostManagement/query`)
   using a service principal with the Cost Management Reader role.
3. Schedule a daily refresh — Cost Management data has a 24h ingestion delay,
   so live queries on every page view are wasteful.

## How services opt in

Add the `costWidget.serviceId` annotation to the service's `catalog-info.yaml`:

```yaml
metadata:
  annotations:
    costWidget.serviceId: payments-api
```

The plugin falls back to `metadata.name` if the annotation is absent.

## Adding the tab in your Backstage app

```tsx
// packages/app/src/components/catalog/EntityPage.tsx
import { EntityCostTab } from '@meridianpay/plugin-cost-widget';

<EntityLayout.Route path="/cost" title="Azure Cost">
  <EntityCostTab />
</EntityLayout.Route>
```
