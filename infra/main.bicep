@description('Location for all resources.')
param location string = 'centralus'

@description('The name of the Azure Cosmos DB account.')
param cosmosAccountName string = 'boranbenjemia'

@description('The name of the App Service plan.')
param appServicePlanName string = 'todoapp-plan'

@description('The name of the App Service.')
param appName string = 'todoapp-backend'

@description('The name of the Azure Static Web App.')
param staticAppName string = 'todoapp-frontend'

@description('Minimum and maximum instances for autoscaling the App Service')
param minInstances int = 1
param maxInstances int = 5

@description('The SKU for the App Service plan')
param skuName string = 'Free'

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  tags: {
    'azd-service-name': 'cosmosdb'
  }
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
    ]
  }
}

resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  name: 'TodoDB'
  parent: cosmosDbAccount
  properties: {
    resource: {
      id: 'TodoDB'
    }
  }
}

resource cosmosDbContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  name: 'Todos'
  parent: cosmosDbDatabase
  properties: {
    resource: {
      id: 'Todos'
      partitionKey: {
        paths: ['/id']
        kind: 'Hash'
      }
    }
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  tags: {
    'azd-service-name': 'appserviceplan'
  }
  // sku: {
  //   name: skuName
  //   tier: 'Standard'
  // }
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: appName
  location: location
  tags: {
    'azd-service-name': 'backend'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'COSMOS_CONNECTION_STRING'
          value: listKeys(cosmosDbAccount.id, '2021-06-15').primaryMasterKey
        }
      ]
    }
  }
}

resource staticWebApp 'Microsoft.Web/staticSites@2021-02-01' = {
  name: staticAppName
  location: location
  // sku: {
  //   name: 'Free'
  //   tier: 'Free'
  // }
  tags: {
    'azd-service-name': 'frontend'
  }
  properties: {
    repositoryUrl: 'https://github.com/BobBJ/architecture'
    branch: 'main'
    buildProperties: {
      appLocation: './frontend'
      apiLocation: './backend'
    }
  }
}

resource appServiceAutoscale 'Microsoft.Insights/autoscalesettings@2021-05-01-preview' = {
  name: 'autoscale-appservice'
  location: location
  properties: {
    profiles: [
      {
        name: 'defaultProfile'
        capacity: {
          minimum: string(minInstances)
          maximum: string(maxInstances)
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: ''
              metricResourceUri: appServicePlan.id
              operator: 'GreaterThan'
              statistic: 'Average'
              threshold: 75
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: ''
              metricResourceUri: appServicePlan.id
              operator: 'LessThan'
              statistic: 'Average'
              threshold: 25
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
          }
        ]
      }
    ]
    enabled: true
    targetResourceUri: appServicePlan.id
  }
}
