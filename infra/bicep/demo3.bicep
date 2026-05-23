// demo3.bicep — deploys the additional Azure resources required for Demo 3
// (Backstage Developer Portal). Run after `azd provision` has already created
// the shared resources (ACR, Key Vault, Container Apps Env, monitoring).
//
// Usage:
//   az deployment group create \
//     --resource-group rg-<env> \
//     --template-file infra/bicep/demo3.bicep \
//     --parameters @infra/bicep/parameters/demo3.parameters.json \
//     --parameters postgresPassword=<secret> msClientSecret=<secret> githubToken=<secret>

@description('Name of the azd environment — must match the environment used in azd provision.')
param environmentName string

@description('Azure region.')
param location string = resourceGroup().location

@description('Tags applied to all resources.')
param tags object = {
  'azd-env-name': environmentName
  project: 'code-to-cloud-demo'
  demo: 'demo3'
  managedBy: 'az-cli'
}

// ─── Shared resources (must already exist from azd provision) ─────────────────
param containerRegistryName string
param keyVaultName string
param containerAppsEnvironmentId string

@secure()
param appInsightsConnectionString string

// ─── PostgreSQL credentials ───────────────────────────────────────────────────
@secure()
@description('Password for the PostgreSQL administrator. Min 8 chars, complexity required.')
param postgresPassword string

// ─── Microsoft Entra ID (OAuth) ──────────────────────────────────────────────
@description('Client ID of the Entra ID app registration for Backstage SSO.')
param msClientId string = ''

@secure()
@description('Client secret of the Entra ID app registration.')
param msClientSecret string = ''

@description('Tenant ID for Microsoft auth.')
param msTenantId string = ''

// ─── GitHub ───────────────────────────────────────────────────────────────────
@secure()
@description('GitHub PAT used by the Backstage scaffolder to create repositories.')
param githubToken string = ''

// ─── PostgreSQL ───────────────────────────────────────────────────────────────
module postgres 'modules/postgresql.bicep' = {
  name: 'postgresql'
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    administratorPassword: postgresPassword
  }
}

// ─── Backstage Container App ──────────────────────────────────────────────────
module backstage 'modules/backstage.bicep' = {
  name: 'backstage'
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironmentId
    containerRegistryName: containerRegistryName
    keyVaultName: keyVaultName
    appInsightsConnectionString: appInsightsConnectionString
    postgresHost: postgres.outputs.serverFqdn
    postgresDatabase: postgres.outputs.databaseName
    postgresUser: postgres.outputs.administratorLogin
    postgresPassword: postgresPassword
    msClientId: msClientId
    msClientSecret: msClientSecret
    msTenantId: msTenantId
    githubToken: githubToken
  }
  dependsOn: [postgres]
}

// ─── Outputs ─────────────────────────────────────────────────────────────────
output POSTGRES_HOST string = postgres.outputs.serverFqdn
output POSTGRES_DB   string = postgres.outputs.databaseName
output POSTGRES_USER string = postgres.outputs.administratorLogin

output BACKSTAGE_NAME string = backstage.outputs.backstageName
output BACKSTAGE_URI  string = backstage.outputs.backstageUri
