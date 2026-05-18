targetScope = 'subscription'

@minLength(1)
@maxLength(32)
@description('Name of the azd environment — used as the suffix for all resources.')
param environmentName string

@description('Azure region for all resources.')
param location string = 'canadacentral'

@description('Resource group that will hold the environment.')
param resourceGroupName string = 'rg-${environmentName}'

@description('Optional AAD principal (object id) to grant Key Vault secret access.')
param principalId string = ''

var tags = {
  'azd-env-name': environmentName
  project: 'code-to-cloud-demo'
  managedBy: 'azd'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
    tags: tags
  }
}

module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVault'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    principalId: principalId
  }
}

module acr 'modules/container-registry.bicep' = {
  name: 'acr'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
    tags: tags
  }
}

module containerApps 'modules/container-apps.bicep' = {
  name: 'containerApps'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsId
    containerRegistryName: acr.outputs.name
    keyVaultName: keyVault.outputs.name
  }
  dependsOn: [
    monitoring
    acr
    keyVault
  ]
}

output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_LOCATION string = location
output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = containerApps.outputs.environmentId
output AZURE_CONTAINER_APPS_ENVIRONMENT_NAME string = containerApps.outputs.environmentName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.name
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output SERVICE_API_URI string = containerApps.outputs.apiUri
output SERVICE_API_NAME string = containerApps.outputs.apiName

@secure()
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.appInsightsConnectionString
