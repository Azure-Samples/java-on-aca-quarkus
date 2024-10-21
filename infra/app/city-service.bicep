/* -------------------------------------------------------------------------- */
/*                                 PARAMETERS                                 */
/* -------------------------------------------------------------------------- */

@description('Name of the container app.')
param name string

@description('Location in which the resources will be deployed. Default value is the resource group location.')
param location string = resourceGroup().location

@description('Tags that will be added to all the resources. For Azure Developer CLI, "azd-env-name" should be added to the tags.')
param tags object = {}

@description('Name of the service. This name is used to add "azd-service-name" tag to the tags for the container app. Default value is "city-service". If you change this value, make sure to change the name of the service in "azure.yaml" file as well.')
param serviceName string = 'city-service'

@description('Name of the identity that will be created and used by the container app to pull image from the container registry.')
param identityName string

@description('Name of the existing container apps environment.')
param containerAppsEnvironmentName string

@description('Name of the existing container registry that will be used by the container app.')
param containerRegistryName string

@description('Flag that indicates whether the container app already exists or not. This is used in container app upsert to set the image name to the value of the existing container apps image name.')
param exists bool

/* ------------------------------- PostgreSQL ------------------------------- */

@description('Name of the existing Postgres Flexible Server. This is the relational database used by the Quarkus city-service App to save cities.')
param postgresFlexibleServerName string

@description('Name of the Postgres database. Several databases can be created in the same Postgres Flexible Server. We need to know the one that is created for this microservice.')
param postgresDatabaseName string

@description('Username of the Postgres Flexible Server administrator. This is the administrator that was set when the Postgres Flexible Server was created.')
param postgresAdminUsername string

@secure()
@description('Password of the Postgres Flexible Server administrator. This is the password that was set when the Postgres Flexible Server was created.')
param postgresAdminPassword string

/* -------------------------------------------------------------------------- */
/*                                  VARIABLES                                 */
/* -------------------------------------------------------------------------- */

@description('Quarkus Data Source JDBC URL. It is composed of the Postgres Flexible Server FQDN and the database name.')
var quarkusDatasourceJdbcUrl = 'jdbc:postgresql://${postgresFlexibleServer.properties.fullyQualifiedDomainName}:5432/${postgresDatabaseName}?sslmode=require'

@description('Quarkus Data Source Reactive URL. It is composed of the Postgres Flexible Server FQDN and the database name.')
var quarkusDatasourceReactiveUrl = 'postgresql://${postgresFlexibleServer.properties.fullyQualifiedDomainName}:5432/${postgresDatabaseName}?sslmode=require'


/* -------------------------------------------------------------------------- */
/*                                  RESOURCES                                 */
/* -------------------------------------------------------------------------- */

resource postgresFlexibleServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' existing = {
  name: postgresFlexibleServerName
}

resource cityServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
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
    secrets: {
      jdbcurl: quarkusDatasourceJdbcUrl
      reactiveurl: quarkusDatasourceReactiveUrl
      dbusername: postgresAdminUsername
      dbpassword: postgresAdminPassword
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
output CITY_SERVICE_IDENTITY_PRINCIPAL_ID string = cityServiceIdentity.properties.principalId

@description('Name of the container app.')
output CITY_SERVICE_NAME string = app.outputs.name

@description('URI of the container app.')
output CITY_SERVICE_URI string = app.outputs.uri

@description('Name of the container apps image.')
output CITY_SERVICE_IMAGE_NAME string = app.outputs.imageName
