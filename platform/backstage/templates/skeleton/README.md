# ${{ values.name }}

${{ values.description }}

## What is this

`${{ values.name }}` is a .NET 8 service owned by `${{ values.owner }}` and deployed to Azure Container Apps via `azd`. It was scaffolded from the Meridian Pay platform's "New .NET Azure Service" template, so it ships with infrastructure-as-code, CI/CD, a Backstage catalog entry, and TechDocs out of the box.

## Local Development

```bash
cd apps/${{ values.name }}
dotnet restore
dotnet run
```

The service listens on http://localhost:8080 by default. A `GET /` returns the service name as a health probe.

## Deploy

```bash
azd auth login
azd env new ${{ values.azureEnvironment }}
azd up
```

`azd up` provisions infrastructure (`infra/bicep`) and deploys the service in a single step. Subsequent code-only deploys can use `azd deploy`.

## Owner

`${{ values.owner }}` — see the Backstage catalog entry for current on-call and escalation paths.

## Region

Deployed to **${{ values.azureLocation }}**.

## Cost

Live monthly Azure spend for this service is visible on the **Cost** tab of the Backstage catalog page. Data refreshes every 5 minutes from Azure Cost Management.
