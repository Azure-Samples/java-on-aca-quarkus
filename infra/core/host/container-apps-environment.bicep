metadata description = 'Creates an Azure Container Apps environment.'
param name string
param location string = resourceGroup().location
param tags object = {}

@description('Name of the Application Insights resource')
param applicationInsightsName string = ''

@description('Specifies if OpenTelemetry is enabled')
param openTelemetryEnabled bool = false

@description('Specifies if Dapr is enabled')
param daprEnabled bool = false

@description('Name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-02-02-preview' = if (openTelemetryEnabled && !empty(applicationInsightsName)) {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    daprAIInstrumentationKey: daprEnabled ? applicationInsights.properties.InstrumentationKey : ''
    appInsightsConfiguration: {
      connectionString: applicationInsights.properties.ConnectionString
    }
    openTelemetryConfiguration: {
      tracesConfiguration: {
        destinations: ['appInsights']
      }
      logsConfiguration: {
        destinations: ['appInsights']
      }
    }
  }
}

resource containerAppsEnvironmentOTELDisabled 'Microsoft.App/managedEnvironments@2024-03-01' = if (!openTelemetryEnabled) {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    daprAIInstrumentationKey: daprEnabled && !empty(applicationInsightsName) ? applicationInsights.properties.InstrumentationKey : ''
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if ((daprEnabled || openTelemetryEnabled) && !empty(applicationInsightsName)) {
  name: applicationInsightsName
}

output defaultDomain string = openTelemetryEnabled && !empty(applicationInsightsName) ? containerAppsEnvironment.properties.defaultDomain : containerAppsEnvironmentOTELDisabled.properties.defaultDomain
output id string = openTelemetryEnabled && !empty(applicationInsightsName) ? containerAppsEnvironment.id : containerAppsEnvironmentOTELDisabled.id
output name string = openTelemetryEnabled && !empty(applicationInsightsName) ? containerAppsEnvironment.name : containerAppsEnvironmentOTELDisabled.name
