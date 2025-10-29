@description('Prefix for resource names')
param prefix string = 'loi09'

@description('Location for resources')
param location string = resourceGroup().location

@description('SKU for storage account')
param storageSku string = 'Standard_LRS'

var evidencestorageName = toLower('${prefix}evidence')
var funcStorageName = toLower('${prefix}funcsa')
var funcAppName = toLower('${prefix}-evidence-func')
var kvName = toLower('${prefix}kv')
var identityName = '${prefix}-automation-identity'
var logAnalyticsName = '${prefix}-laworkspace'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

resource evidenceStorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: evidencestorageName
  location: location
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource funcStorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: funcStorageName
  location: location
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${prefix}-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'functionapp'
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: funcAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: funcStorage.properties.primaryEndpoints.blob
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'EVIDENCE_STORAGE_ACCOUNT'
          value: evidenceStorage.name
        }
        {
          name: 'KEY_VAULT_NAME'
          value: kvName
        }
        {
          name: 'MANAGED_IDENTITY_CLIENT_ID'
          value: identity.properties.clientId
        }
      ]
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  dependsOn: [
    appServicePlan
    funcStorage
    identity
  ]
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: kvName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: identity.properties.principalId
        permissions: {
          keys: [
            'get',
            'wrapKey',
            'unwrapKey',
            'sign',
            'verify'
          ]
          secrets: [
            'get',
            'set'
          ]
        }
      }
    ]
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
  }
  dependsOn: [
    identity
  ]
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

output functionAppName string = functionApp.name
output evidenceStorageAccount string = evidenceStorage.name
output keyVaultName string = keyVault.name
output managedIdentityClientId string = identity.properties.clientId
output logAnalyticsWorkspace string = logAnalytics.name

