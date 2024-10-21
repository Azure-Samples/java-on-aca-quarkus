/* -------------------------------------------------------------------------- */
/*                                 PARAMETERS                                 */
/* -------------------------------------------------------------------------- */

@description('Name of the container app.')
param name string

@description('Location in which the resources will be deployed. Default value is the resource group location.')
param location string = resourceGroup().location

@description('Tags that will be added to all the resources. For Azure Developer CLI, "azd-env-name" should be added to the tags.')
param tags object = {}

@description('Name of the service. This name is used to add "azd-service-name" tag to the tags for the container app. Default value is "weather-service". If you change this value, make sure to change the name of the service in "azure.yaml" file as well.')
param serviceName string = 'weather-service'

@description('Name of the identity that will be created and used by the container app to pull image from the container registry.')
param identityName string

@description('Name of the existing container apps environment.')
param containerAppsEnvironmentName string

@description('Name of the existing container registry that will be used by the container app.')
param containerRegistryName string

@description('Hostname suffix for container registry. Set when deploying to sovereign clouds')
param containerRegistryHostSuffix string = 'azurecr.io'

@description('Flag that indicates whether the container app already exists or not. This is used in container app upsert to set the image name to the value of the existing container apps image name.')
param exists bool

/* ------------------------------- MySQL ------------------------------- */

@description('Name of the existing MySQL Flexible Server. This is the relational database used by the Quarkus weather-service App to save weather of cities.')
param mysqlFlexibleServerName string

@description('Name of the MySQL database. Several databases can be created in the same MySQL Flexible Server. We need to know the one that is created for this microservice.')
param mysqlDatabaseName string

@description('Username of the MySQL Flexible Server administrator. This is the administrator that was set when the MySQL Flexible Server was created.')
param mysqlAdminUsername string

@secure()
@description('Password of the MySQL Flexible Server administrator. This is the password that was set when the MySQL Flexible Server was created.')
param mysqlAdminPassword string

/* -------------------------------------------------------------------------- */
/*                                  VARIABLES                                 */
/* -------------------------------------------------------------------------- */

@description('Quarkus Data Source JDBC URL. It is composed of the MySQL Flexible Server FQDN and the database name.')
var quarkusDatasourceJdbcUrl = 'jdbc:mysql://${mysqlFlexibleServer.properties.fullyQualifiedDomainName}:3306/${mysqlDatabaseName}'

@description('Quarkus Data Source Reactive URL. It is composed of the MySQL Flexible Server FQDN and the database name.')
var quarkusDatasourceReactiveUrl = 'mysql://${mysqlFlexibleServer.properties.fullyQualifiedDomainName}:3306/${mysqlDatabaseName}'


/* -------------------------------------------------------------------------- */
/*                                  RESOURCES                                 */
/* -------------------------------------------------------------------------- */

resource mysqlFlexibleServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' existing = {
  name: mysqlFlexibleServerName
}

resource weatherServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

module app '../core/host/container-app-upsert.bicep' = {
  name: '${serviceName}-container-app'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    identityType: 'UserAssigned'
    identityName: identityName
    exists: exists
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    containerRegistryHostSuffix: containerRegistryHostSuffix
    secrets: {
      jdbcurl: quarkusDatasourceJdbcUrl
      reactiveurl: quarkusDatasourceReactiveUrl
      dbusername: mysqlAdminUsername
      dbpassword: mysqlAdminPassword
    }
    env: [
      {
        name: 'QUARKUS_DATASOURCE_JDBC_URL'
        secretRef: 'jdbcurl'
      }
      {
        name: 'QUARKUS_DATASOURCE_REACTIVE_URL'
        secretRef: 'reactiveurl'
      }
      {
        name: 'QUARKUS_DATASOURCE_USERNAME'
        secretRef: 'dbusername'
      }
      {
        name: 'QUARKUS_DATASOURCE_PASSWORD'
        secretRef: 'dbpassword'
      }
    ]
    targetPort: 8080
  }
}

/* -------------------------------------------------------------------------- */
/*                                   OUTPUTS                                  */
/* -------------------------------------------------------------------------- */

@description('ID of the service principal that is used by the container app to pull image from the container registry.')
output WEATHER_SERVICE_IDENTITY_PRINCIPAL_ID string = weatherServiceIdentity.properties.principalId

@description('Name of the container app.')
output WEATHER_SERVICE_NAME string = app.outputs.name

@description('URI of the container app.')
output WEATHER_SERVICE_URI string = app.outputs.uri

@description('Name of the container apps image.')
output WEATHER_SERVICE_IMAGE_NAME string = app.outputs.imageName
