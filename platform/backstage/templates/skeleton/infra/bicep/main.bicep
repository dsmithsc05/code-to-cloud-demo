targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
  'meridianpay:service': '${{ values.name }}'
  'meridianpay:owner': '${{ values.owner }}'
}

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${{ values.name }}-${environmentName}'
  location: location
  tags: tags
}

module containerApp 'modules/container-app.bicep' = {
  scope: rg
  name: 'containerApp'
  params: {
    name: '${{ values.name }}-${resourceToken}'
    location: location
    tags: tags
  }
}

output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = rg.name
output SERVICE_URI string = containerApp.outputs.uri
