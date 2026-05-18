@description('Name of the azd environment.')
param environmentName string

@description('Azure region.')
param location string

@description('Tags applied to all resources.')
param tags object

// ACR names must be 5-50 chars, lowercase alphanumeric only — strip hyphens.
var acrName = toLower('acr${replace(environmentName, '-', '')}')

resource registry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    // Admin user disabled — workloads pull via user-assigned managed identity.
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
    anonymousPullEnabled: false
  }
}

output id string = registry.id
output name string = registry.name
output loginServer string = registry.properties.loginServer
