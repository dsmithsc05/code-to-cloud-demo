@description('Name of the azd environment.')
param environmentName string

@description('Azure region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Optional AAD principal id to grant Key Vault Secrets User.')
param principalId string = ''

// KV names: 3-24 chars, lowercase alphanumeric + hyphens, must start with a letter.
// Build deterministic-but-short name from a hash + truncated env name.
var rawName = 'kv-${take(uniqueString(subscription().id, environmentName), 8)}-${take(environmentName, 12)}'
var vaultName = toLower(take(rawName, 24))

// Built-in role: Key Vault Secrets User
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaultName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: false
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource principalSecretsAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(vault.id, principalId, keyVaultSecretsUserRoleId)
  scope: vault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: principalId
    principalType: 'User'
  }
}

output id string = vault.id
output name string = vault.name
output endpoint string = vault.properties.vaultUri
