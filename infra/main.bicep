targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

/* -------------------------------------------------------------------------- */
/*                                 PARAMETERS                                 */
/* -------------------------------------------------------------------------- */

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions.

/* ----------------------------- Resource Names ----------------------------- */

@maxLength(90)
@description('Name of the resource group to deploy. If not specified, a name will be generated.')
param resourceGroupName string = ''

@maxLength(60)
@description('Name of the container apps environment to deploy. If not specified, a name will be generated. The maximum length is 60 characters.')
param containerAppsEnvironmentName string = ''

@maxLength(50)
@description('Name of the container registry to deploy. If not specified, a name will be generated. The name is global and must be unique within Azure. The maximum length is 50 characters.')
param containerRegistryName string = ''

@description('Hostname suffix for container registry. Set when deploying to sovereign clouds')
param containerRegistryHostSuffix string = 'azurecr.io'

@maxLength(63)
@description('Name of the log analytics workspace to deploy. If not specified, a name will be generated. The maximum length is 63 characters.')
param logAnalyticsWorkspaceName string = ''

@maxLength(255)
@description('Name of the application insights to deploy. If not specified, a name will be generated. The maximum length is 255 characters.')
param applicationInsightsName string = ''

@maxLength(160)
@description('Name of the application insights dashboard to deploy. If not specified, a name will be generated. The maximum length is 160 characters.')
param applicationInsightsDashboardName string = ''

@maxLength(63)
@description('Name of the PostgreSQL flexible server to deploy. If not specified, a name will be generated. The name is global and must be unique within Azure. The maximum length is 63 characters. It contains only lowercase letters, numbers and hyphens, and cannot start nor end with a hyphen.')
param postgresFlexibleServerName string = ''

/* ------------------------------- PostgreSQL ------------------------------- */

@description('Name of the PostgreSQL database.')
param postgresDatabaseName string = 'demodb'

@description('Name of the PostgreSQL admin user.')
param postgresAdminUsername string = 'demouser'

@secure()
@description('Password for the PostgreSQL admin user. If not specified, a password will be generated.')
param postgresAdminPassword string = newGuid()

@maxLength(64)
@description('Name of the MySQL flexible server to deploy. If not specified, a name will be generated. The name is global and must be unique within Azure. The maximum length is 64 characters. It contains only lowercase letters, numbers and hyphens, and cannot start nor end with a hyphen.')
param mysqlFlexibleServerName string = ''

/* ------------------------------- MySQL ------------------------------- */

@description('Name of the MySQL database.')
param mysqlDatabaseName string = 'demodb'

@description('Name of the MySQL admin user.')
param mysqlAdminUsername string = 'demouser'

@secure()
@description('Password for the MySQL admin user. If not specified, a password will be generated.')
param mysqlAdminPassword string = newGuid()

/* ------------------------------ city-service ------------------------------ */

@maxLength(32)
@description('Name of the city-serivce container app to deploy. If not specified, a name will be generated. The maximum length is 32 characters.')
param cityServiceContainerAppName string = ''

@description('Set if the city-service container app already exists.')
param cityServiceAppExists bool = false

/* ------------------------------ weather-service ------------------------------ */

@maxLength(32)
@description('Name of the weather-service container app to deploy. If not specified, a name will be generated. The maximum length is 32 characters.')
param weatherServiceContainerAppName string = ''

@description('Set if the weather-service container app already exists.')
param weatherServiceAppExists bool = false

/* ------------------------------ gateway ------------------------------ */

@maxLength(32)
@description('Name of the gateway container app to deploy. If not specified, a name will be generated. The maximum length is 32 characters.')
param gatewayContainerAppName string = ''

@description('Set if the gateway container app already exists.')
param gatewayAppExists bool = false

/* ------------------------------ weather-app ------------------------------ */

@maxLength(32)
@description('Name of the weather-app container app to deploy. If not specified, a name will be generated. The maximum length is 32 characters.')
param weatherAppContainerAppName string = ''

@description('Set if the weather-app container app already exists.')
param weatherFrontendAppExists bool = false

/* -------------------------------------------------------------------------- */
/*                                  VARIABLES                                 */
/* -------------------------------------------------------------------------- */

@description('abbrs prefix for resources.')
var abbrs = loadJsonContent('./abbreviations.json')

@description('Unique token used for global resource names. Unique string returns a 13 characters long string.')
// See: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#remarks-4
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

@description('Name of the environment with only alphanumeric characters. Used for resource names that require alphanumeric characters only.')
var alphaNumericEnvironmentName = replace(replace(environmentName, '-', ''), ' ', '')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

/* ----------------------------- Resource Names ----------------------------- */

var _resourceGroupName = !empty(resourceGroupName) ? resourceGroupName : take('${abbrs.resourcesResourceGroups}${environmentName}', 90)
var _containerAppsEnvironmentName = !empty(containerAppsEnvironmentName) ? containerAppsEnvironmentName : take('${abbrs.appManagedEnvironments}${environmentName}', 60)
var _logAnalyticsWorkspaceName = !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : take('${abbrs.operationalInsightsWorkspaces}${environmentName}', 63)
var _applicationInsightsName = !empty(applicationInsightsName) ? applicationInsightsName : take('${abbrs.insightsComponents}${environmentName}', 255)
var _applicationInsightsDashboardName = !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : take('${abbrs.portalDashboards}${environmentName}', 160)
var _cityServiceContainerAppName = !empty(cityServiceContainerAppName) ? cityServiceContainerAppName : take('${abbrs.appContainerApps}city-service-${environmentName}', 32)
var _cityServiceIdentityName = '${abbrs.managedIdentityUserAssignedIdentities}city-service-${resourceToken}'
var _weatherServiceContainerAppName = !empty(weatherServiceContainerAppName) ? weatherServiceContainerAppName : take('${abbrs.appContainerApps}weather-service-${environmentName}', 32)
var _weatherServiceIdentityName = '${abbrs.managedIdentityUserAssignedIdentities}weather-service-${resourceToken}'
var _gatewayContainerAppName = !empty(gatewayContainerAppName) ? gatewayContainerAppName : take('${abbrs.appContainerApps}gateway-${environmentName}', 32)
var _gatewayIdentityName = '${abbrs.managedIdentityUserAssignedIdentities}gateway-${resourceToken}'
var _weatherAppContainerAppName = !empty(weatherAppContainerAppName) ? weatherAppContainerAppName : take('${abbrs.appContainerApps}weather-app-${environmentName}', 32)
var _weatherAppIdentityName = '${abbrs.managedIdentityUserAssignedIdentities}weather-app-${resourceToken}'

/* --------------------- Globally Unique Resource Names --------------------- */

// 'cr' is 2 characters long, 'resourceToken' is 13 characters long, so, as the maximum length is 50 characters, the environment name can be maximum 35 characters long.
// The 'take(..., 50)' function is used to ensure the name is not longer than 50 characters, even if it is not necessary.
// The name can contains only alpha numeric characters and no hyphens. This is why 'alphaNumericEnvironmentName' is used instead of 'environmentName'.
var _containerRegistryName = !empty(containerRegistryName) ? containerRegistryName : take('${abbrs.containerRegistryRegistries}${take(alphaNumericEnvironmentName, 35)}${resourceToken}', 50)

// 'psql-' is 5 characters long, 'resourceToken' is 13 characters long, there is one hyphen, so, as the maximum length is 63 characters, the environment name can be maximum 44 characters long.
// The 'take(..., 63)' function is used to ensure the name is not longer than 63 characters, even if it is not necessary.
// The name needs to be lower case, so  it is converted to lower case.
var _postgresFlexibleServerName = !empty(postgresFlexibleServerName) ? postgresFlexibleServerName : take(toLower('${abbrs.dBforPostgreSQLServers}${take(environmentName, 44)}-${resourceToken}'), 63)

// 'mysql-' is 6 characters long, 'resourceToken' is 13 characters long, there is one hyphen, so, as the maximum length is 64 characters, the environment name can be maximum 44 characters long.
// The 'take(..., 64)' function is used to ensure the name is not longer than 64 characters, even if it is not necessary.
// The name needs to be lower case, so  it is converted to lower case.
var _mysqlFlexibleServerName = !empty(mysqlFlexibleServerName) ? mysqlFlexibleServerName : take(toLower('${abbrs.dBforMySQLServers}${take(environmentName, 44)}-${resourceToken}'), 64)

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: _resourceGroupName
  location: location
  tags: tags
}

// Add resources to be provisioned below.
// A full example that leverages azd bicep modules can be seen in the todo-python-mongo template:
// https://github.com/Azure-Samples/todo-python-mongo/tree/main/infra

/* -------------------------------------------------------------------------- */
/*                                  RESOURCES                                 */
/* -------------------------------------------------------------------------- */

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: _logAnalyticsWorkspaceName
    applicationInsightsName: _applicationInsightsName
    applicationInsightsDashboardName: _applicationInsightsDashboardName
  }
}

// Container apps host (including container registry)
module containerApps './core/host/container-apps.bicep' = {
  name: 'container-apps'
  scope: rg
  params: {
    name: 'app'
    location: location
    tags: tags
    containerAppsEnvironmentName: _containerAppsEnvironmentName
    containerRegistryName: _containerRegistryName
    // Work around Azure/azure-dev#3157 (the root cause of which is Azure/acr#723) by explicitly enabling the admin user to allow users which
    // don't have the `Owner` role granted (and instead are classic administrators) to access the registry to push even if AAD authentication fails.
    //
    // This addresses the following error during deploy:
    //
    // failed getting ACR token: POST https://<some-random-name>.azurecr.io/oauth2/exchange 401 Unauthorized
    containerRegistryAdminUserEnabled: true
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    openTelemetryEnabled: true
  }
}

module postgresFlexibleServer 'core/database/postgresql/flexibleserver.bicep' = {
  name: 'postgresql-flexible-server'
  scope: rg
  params: {
    name: _postgresFlexibleServerName
    location: location
    tags: tags
    version: '16'
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
    }
    storage: {
      storageSizeGB: 32
      autoGrow: 'Disabled'
    }
    administratorLogin: postgresAdminUsername
    administratorLoginPassword: postgresAdminPassword
    databaseNames: [
      postgresDatabaseName
    ]
    allowAzureIPsFirewall: true
  }
}

module cityService './app/city-service.bicep' = {
  name: 'city-service'
  scope: rg
  params: {
    name: _cityServiceContainerAppName
    location: location
    tags: tags
    identityName: _cityServiceIdentityName
    postgresFlexibleServerName: postgresFlexibleServer.outputs.name
    postgresDatabaseName: postgresDatabaseName
    postgresAdminUsername: postgresAdminUsername
    postgresAdminPassword: postgresAdminPassword
    exists: cityServiceAppExists
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    containerRegistryHostSuffix: containerRegistryHostSuffix
  }
}

module mysqlFlexibleServer 'core/database/mysql/flexibleserver.bicep' = {
  name: 'mysql-flexible-server'
  scope: rg
  params: {
    name: _mysqlFlexibleServerName
    location: location
    tags: tags
    version: '8.0.21'
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
    }
    storage: {
      storageSizeGB: 32
      autoGrow: 'Disabled'
    }
    administratorLogin: mysqlAdminUsername
    administratorLoginPassword: mysqlAdminPassword
    databaseNames: [
      mysqlDatabaseName
    ]
    allowAzureIPsFirewall: true
  }
}

module weatherService './app/weather-service.bicep' = {
  name: 'weather-service'
  scope: rg
  params: {
    name: _weatherServiceContainerAppName
    location: location
    tags: tags
    identityName: _weatherServiceIdentityName
    mysqlFlexibleServerName: mysqlFlexibleServer.outputs.name
    mysqlDatabaseName: mysqlDatabaseName
    mysqlAdminUsername: mysqlAdminUsername
    mysqlAdminPassword: mysqlAdminPassword
    exists: weatherServiceAppExists
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    containerRegistryHostSuffix: containerRegistryHostSuffix
  }
}

module gateway './app/gateway.bicep' = {
  name: 'gateway'
  scope: rg
  params: {
    name: _gatewayContainerAppName
    location: location
    tags: tags
    identityName: _gatewayIdentityName
    cityServiceUrl: 'http://${cityService.outputs.CITY_SERVICE_NAME}'
    weatherServiceUrl: 'http://${weatherService.outputs.WEATHER_SERVICE_NAME}'
    exists: gatewayAppExists
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    containerRegistryHostSuffix: containerRegistryHostSuffix
  }
}

module weatherApp './app/weather-app.bicep' = {
  name: 'weather-app'
  scope: rg
  params: {
    name: _weatherAppContainerAppName
    location: location
    tags: tags
    identityName: _weatherAppIdentityName
    gatewayName: gateway.outputs.GATEWAY_NAME
    exists: weatherFrontendAppExists
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    containerRegistryHostSuffix: containerRegistryHostSuffix
  }
}

/* -------------------------------------------------------------------------- */
/*                                   OUTPUTS                                  */
/* -------------------------------------------------------------------------- */

// Add outputs from the deployment here, if needed.
//
// This allows the outputs to be referenced by other bicep deployments in the deployment pipeline,
// or by the local machine as a way to reference created resources in Azure for local development.
// Secrets should not be added here.
//
// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.

@description('The location of all resources.')
output AZURE_LOCATION string = location

@description('The id of the tenant.')
output AZURE_TENANT_ID string = tenant().tenantId

@description('The endpoint of the container registry.')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.registryLoginServer
