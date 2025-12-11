// Bicep template for minimal-cost Azure deployment
// Designed for team sharing - deploy once, everyone uses it
// Follows standard naming conventions
// Estimated cost: $5-15/month

@description('Project code (xx in naming convention, e.g., mcp, ado)')
param projectCode string = 'mcp'

@description('Environment code (dv = dev, qa = qa, pr = prod)')
param environment string = 'dv'

@description('Location code (eus2 = eastus2)')
param locationCode string = 'eus2'

@description('Instance number (001, 002, etc.)')
param instanceNumber string = '001'

// ACR names can only contain alphanumeric (no dashes)
var containerRegistryName = 'acr00${environment}${projectCode}${instanceNumber}'

@description('Azure DevOps organization name')
param orgName string = 'YourOrganization'

@description('Azure DevOps project name')
param projectName string = 'Integration'

@description('Azure DevOps Personal Access Token (stored in Key Vault)')
@secure()
param adoPat string

@description('Location for resources')
param location string = 'eastus2'

@description('Enable external ingress for team access (optional)')
param enableExternalIngress bool = false

// Naming following standard conventions
var resourceGroupName = 'rg-00-integration-${projectCode}-${environment}-${locationCode}-${instanceNumber}'
var containerAppName = 'cap-00-${environment}-${projectCode}-${instanceNumber}'
var containerRegistryName = 'acr-00-${environment}-${projectCode}-${instanceNumber}'
var keyVaultName = 'kyt-00-${environment}-${projectCode}-${instanceNumber}'
var containerAppEnvName = 'cae-00-${environment}-${projectCode}-${instanceNumber}'
var identityName = '${containerAppName}-identity'

// Key Vault for storing PAT securely
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    accessPolicies: []
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: false
  }
}

// Store PAT in Key Vault
resource adoPatSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureDevOpsPAT'
  properties: {
    value: adoPat
  }
}

// Container Registry (Basic tier - $5/month)
// Note: ACR names can only contain alphanumeric (no dashes)
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Container Apps Environment (consumption plan - scales to zero)
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
    }
  }
}

// System-assigned managed identity for ACR pull
resource systemAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

// Grant ACR pull permissions
resource acrPullRole 'Microsoft.ContainerRegistry/registries/roleAssignments@2023-01-01-preview' = {
  parent: containerRegistry
  name: guid(containerRegistry.id, systemAssignedIdentity.id, 'AcrPull')
  properties: {
    principalId: systemAssignedIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe0d1da4b5') // AcrPull
  }
}

// Container App (minimal resources - consumption plan)
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: enableExternalIngress
        targetPort: 3000
        transport: 'http'
        allowInsecure: false
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: systemAssignedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${containerRegistry.properties.loginServer}/mcp-ado-server:latest'
          name: containerAppName
          resources: {
            cpu: json('0.25')  // Minimal CPU
            memory: '0.5Gi'    // Minimal memory
          }
          env: [
            {
              name: 'AZURE_DEVOPS_ORG'
              value: orgName
            }
            {
              name: 'AZURE_DEVOPS_PROJECT'
              value: projectName
            }
            {
              name: 'AZURE_DEVOPS_PAT'
              secretRef: 'azure-devops-pat'
            }
            {
              name: 'NODE_ENV'
              value: 'production'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0  // Scale to zero when not in use
        maxReplicas: 2  // Max 2 replicas for team sharing
      }
    }
  }
}

// Reference to Key Vault secret for Container App
resource keyVaultSecretRef 'Microsoft.App/containerApps/secrets@2023-05-01' = {
  parent: containerApp
  name: 'azure-devops-pat'
  properties: {
    keyVaultUrl: adoPatSecret.properties.secretUriWithVersion
    identity: systemAssignedIdentity.id
  }
}

// Outputs
output resourceGroupName string = resourceGroupName
output containerAppName string = containerApp.name
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output keyVaultName string = keyVault.name
output containerRegistryName string = containerRegistry.name
output estimatedMonthlyCost string = '$5-15/month (Container Registry: $5, Container Apps: $0-10, Key Vault: $0.03)'
output deploymentNote string = 'Deploy once, share with your entire team!'
