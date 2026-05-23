@description('Name of the environment.')
param environmentName string

@description('Azure region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Resource id of the Container Apps managed environment to deploy into.')
param containerAppsEnvironmentId string

@description('Name of the ACR the container is pulled from.')
param containerRegistryName string

@description('Name of the Key Vault holding secrets.')
param keyVaultName string

@description('App Insights connection string.')
@secure()
param appInsightsConnectionString string

@description('PostgreSQL server FQDN.')
param postgresHost string

@description('PostgreSQL database name.')
param postgresDatabase string

@description('PostgreSQL administrator login.')
param postgresUser string

@description('PostgreSQL administrator password.')
@secure()
param postgresPassword string

@description('Microsoft Entra ID client ID for Backstage OAuth.')
param msClientId string

@description('Microsoft Entra ID client secret for Backstage OAuth.')
@secure()
param msClientSecret string

@description('Microsoft Entra ID tenant ID.')
param msTenantId string

@description('GitHub token for the scaffolder.')
@secure()
param githubToken string

@description('Public HTTPS URL of the Backstage portal (e.g. https://ca-backstage-dev.region.azurecontainerapps.io). Leave empty on first provision; the deploy script will inject the real FQDN after creation.')
param backstageBaseUrl string = ''

// ─── Built-in role ids ────────────────────────────────────────────────────────
var acrPullRoleId             = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

// ─── Existing resource references ────────────────────────────────────────────
resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: containerRegistryName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// ─── Managed identity for Backstage ──────────────────────────────────────────
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-backstage-${environmentName}'
  location: location
  tags: tags
}

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, uami.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource kvSecretsUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, uami.id, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ─── Backstage Container App ──────────────────────────────────────────────────
resource backstageApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-backstage-${environmentName}'
  location: location
  tags: union(tags, {
    'azd-service-name': 'backstage'
  })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  dependsOn: [
    acrPullAssignment
    kvSecretsUserAssignment
  ]
  properties: {
    environmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: [
        { name: 'postgres-password', value: postgresPassword            }
        { name: 'ms-client-secret',  value: msClientSecret              }
        { name: 'github-token',      value: githubToken                 }
        { name: 'app-insights-cs',   value: appInsightsConnectionString }
      ]
      ingress: {
        external: true
        targetPort: 7007
        transport: 'auto'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: uami.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'backstage'
          // Placeholder image — deploy-backstage.sh / azd deploy overwrites this
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('1.0')
            memory: '2Gi'
          }
          env: [
            { name: 'NODE_ENV',                               value: 'production'            }
            { name: 'BACKSTAGE_BASE_URL',                     value: backstageBaseUrl        }
            { name: 'BACKSTAGE_BACKEND_BASE_URL',             value: backstageBaseUrl        }
            { name: 'POSTGRES_HOST',                          value: postgresHost            }
            { name: 'POSTGRES_PORT',                          value: '5432'                  }
            { name: 'POSTGRES_USER',                          value: postgresUser            }
            { name: 'POSTGRES_PASSWORD',                      secretRef: 'postgres-password' }
            { name: 'POSTGRES_DB',                            value: postgresDatabase        }
            { name: 'AZURE_CLIENT_ID',                        value: msClientId              }
            { name: 'AZURE_CLIENT_SECRET',                    secretRef: 'ms-client-secret'  }
            { name: 'AZURE_TENANT_ID',                        value: msTenantId              }
            { name: 'GITHUB_TOKEN',                           secretRef: 'github-token'      }
            { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING',  secretRef: 'app-insights-cs'   }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/healthcheck'
                port: 7007
              }
              initialDelaySeconds: 45
              periodSeconds: 30
              failureThreshold: 5
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/healthcheck'
                port: 7007
              }
              initialDelaySeconds: 20
              periodSeconds: 10
              failureThreshold: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 2
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '20'
              }
            }
          }
        ]
      }
    }
  }
}

output backstageName    string = backstageApp.name
output backstageUri     string = 'https://${backstageApp.properties.configuration.ingress.fqdn}'
output identityId       string = uami.id
output identityClientId string = uami.properties.clientId
