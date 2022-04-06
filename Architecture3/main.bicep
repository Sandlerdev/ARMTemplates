/*Parmeters*/
@minLength(3)
@maxLength(3)
@description('This prefix will be applied to new resource names.')
param ResourcePrefix string
@description('By default the region of the resource group will be used for the location of created resources.')
param location string = resourceGroup().location
param IoTHubUnits int = 1

@allowed([
  'B1'
  'B2'
  'B3'
  'F1'
  'S1'
  'S2'
  'S3'
])

@description('Select the SKU assoicateed with the IoT Hub to be created.')
param IoTHubSKU string = 'S1'

@allowed([
  'ITD'
  'OPCUA'
  'FTEG'
])
@description('Select the data source for data being sent to IoT Hub and TSI.  This will dictate the configuration of the Time Series ID property that is configured at creation time.')
param DataSource string = 'FTEG'

@minValue(0)
@maxValue(30)
@description('Select the number of days to hold TSI data in warm storage.  Valid values between 0 and 30.')
param WarmStorageDuration int = 7


/*Variables */
var blobStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${IoTStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(IoTStorage.id, IoTStorage.apiVersion).keys[0].value}'

var eventHubName = 'telemetrydata'
var eventSourceName = '${TSIEVN.name}/${ResourcePrefix}EventSource'
var IoTHubName = '${ResourcePrefix}IoTHub'
var TSIConsumerGroupName = 'tsieventhub' 


var timeSeriesIdPropertiesKey1 = 'iothub-connection0device-id'
var timeSeriesIdPropertiesKey2 = 'gatewayData.model_id'

var eventHubSKUName = 'Standard'
var eventHubSKUTier = 'Standard'
var eventHubSKUCapactity = 1
var eventHubNSName =  '${ResourcePrefix}EventTHub'
var eventHubIOTName = '${EventHubNS.name}/iothubdata'
var eventHubTelemName = '${EventHubNS.name}/telemetrydata' 

var serverFarmName = '${ResourcePrefix}ServerFarm'
var dockerRegistryResource_id = '/subscriptions/4753dce4-4462-4424-9529-c4653adadf81/resourceGroups/EIDev-Artifacts/providers/Microsoft.ContainerRegistry/registries/EIDevContainers'
var dockerRegistryServerURL = 'https://eidevcontainers.azurecr.io'
var dockerRegistryServerUserName = 'EIDevContainers'
var dockerRegistryServerPassword = 'NCYVeH28bRqRIbzrQp4bmAuejpRy38F/'


/*Resources*/
resource IoTStorage 'Microsoft.Storage/storageAccounts@2021-08-01'= {
  name: '${ResourcePrefix}${uniqueString(resourceGroup().id)}storage'
  location: location
  kind: 'StorageV2'

  sku:{
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    
  }
  
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-08-01' = {
  name: 'default'
  parent: IoTStorage
  

}

resource IoTHub 'Microsoft.Devices/IotHubs@2021-07-02'= {
  name: IoTHubName
  location: location
  sku:{
    name: IoTHubSKU
    capacity: IoTHubUnits
    
  }
  properties:{
    ipFilterRules: []
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: 4
      }
    }
    //routing
    routing: {
      endpoints: {
        serviceBusQueues: []
        serviceBusTopics: []
        eventHubs: [
          {
            connectionString: iotsendauthrules.listKeys().primaryConnectionString
            authenticationType: 'keyBased'
            name: 'EventHubRouteEndPoint'
          }
        ]
        storageContainers: []
      }
      enrichments: []
      routes: [
        {
          name: 'telemetrytoEH'
          source: 'DeviceMessages'
          condition: 'true'
          endpointNames: [
            'EventHubRouteEndPoint'
          ]
          isEnabled: true
        }
      ]
      fallbackRoute: {
        name: '$fallback'
        source: 'DeviceMessages'
        condition: 'true'
        endpointNames: [
          'events'
        ]
        isEnabled: true
      }
    }

    //end routing

     storageEndpoints: {
      '$default': {
        sasTtlAsIso8601: 'PT1H'
        connectionString: blobStorageConnectionString
        containerName: 'initialuploads'
        authenticationType: 'keyBased'
      }
    }
    messagingEndpoints: {
      fileNotifications: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    enableFileUploadNotifications: true
    cloudToDevice: {
      maxDeliveryCount: 10
      defaultTtlAsIso8601: 'PT1H'
      feedback: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
  }

}

resource EventHubNS 'Microsoft.EventHub/namespaces@2021-11-01' = {
  sku: {
    name: eventHubSKUName
    tier: eventHubSKUTier
    capacity:eventHubSKUCapactity
  }
  name: eventHubNSName
  location: location
 
  properties: {
    disableLocalAuth: false
    zoneRedundant: true
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    kafkaEnabled: true
  }
}

resource iothubdata 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = {
  name: eventHubIOTName
  properties: {
    messageRetentionInDays: 1
    partitionCount: 4
    status: 'Active'
  }
}

resource telemetrydata 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = {
  name: eventHubTelemName
  properties: {
    messageRetentionInDays: 1
    partitionCount: 4
    status: 'Active'
  }
}


resource TSIES 'Microsoft.TimeSeriesInsights/environments/eventSources@2020-05-15' = {
  kind: 'Microsoft.EventHub'
  location: location
 
  properties: {
    sharedAccessKey: telemetryTSIlistenauthrules.listKeys().primaryKey
    eventSourceResourceId: telemetrydata.name  
    eventHubName: eventHubName
    consumerGroupName: TSIConsumerGroupName
    keyName:'TSI'
    serviceBusNamespace: EventHubNS.name
    timestampPropertyName: 'body.gatewayData.vqts.t'

  }
  name: eventSourceName 
}

resource TSIEVN 'Microsoft.TimeSeriesInsights/environments@2020-05-15' = {
  sku: {
    name: 'L1'
    capacity: 1
  }
  kind: 'Gen2'
  location: location
  tags: {
    
  }
  properties: {
    storageConfiguration: {
      accountName: '${IoTStorage.name}'
      managementKey: '${IoTStorage.listKeys().keys[0].value}'
    }

    timeSeriesIdProperties: [
      {
        name: timeSeriesIdPropertiesKey1
        type: 'String'
      }
      {
        name: timeSeriesIdPropertiesKey2 
        type: 'String'
      }
    ]
    warmStoreConfiguration: {
      dataRetention: 'P${WarmStorageDuration}D'
    }
  }
  name: '${ResourcePrefix}TSI'
}



resource serverFarm 'Microsoft.Web/serverfarms@2021-03-01'= {
  name: serverFarmName
  kind: 'linux' //'elastic'
  location: location
  properties:{
    perSiteScaling: false
    maximumElasticWorkerCount: 20
    elasticScaleEnabled: true
    targetWorkerSizeId: 0
    targetWorkerCount: 0
    reserved: true


  }
  sku:{
    name: 'EP1'
    tier: 'ElasticPremium'
    size: 'EP1'
    family: 'EP'
    capacity: 1 
  }
}



  resource iotsendauthrules 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-11-01' ={
  name: '${EventHubNS.name}/iothubdata/iothubroutes_prototypeDev-hub'
  dependsOn: [
    iothubdata
  ]
  properties:{
    rights:[
      'Send'
    ]
  }
}

resource iotlistenauthrules 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-11-01' ={
  name: '${EventHubNS.name}/iothubdata/IoTMessageParser'
  dependsOn: [
    iothubdata
  ]
  properties:{
    rights:[
      'Listen'
    ]
  }
}

resource telemetrySendauthrules 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-11-01' ={
  name: '${EventHubNS.name}/telemetrydata/IoTMessageParser'
  dependsOn: [
    telemetrydata
  ]
  properties:{
    rights:[
      'Send'
    ]
  }
}

resource telemetryTSIlistenauthrules 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-11-01' ={
  name: '${EventHubNS.name}/telemetrydata/TSI'
  dependsOn: [
    telemetrydata
  ]
  properties:{
    rights:[
      'Listen'
    ]
  }
}

resource telemetryEHConsumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2021-11-01' = {
  name: '${telemetrydata.name}/$Default'
  dependsOn: [
    EventHubNS
  ]
}

resource iotMessageParserEHConsumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2021-11-01' = {
  name: '${iothubdata.name}/iotmessageparser'
  dependsOn: [
    EventHubNS
  ]
}

resource tsiEHConsumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2021-11-01' = {
  name: '${telemetrydata.name}/tsieventhub'
  dependsOn: [
    EventHubNS
  ]
}


/*Azure Functions*/
resource ITDBlobParser 'Microsoft.Web/sites@2021-03-01' = {
  name: '${ResourcePrefix}ITDBlobParser'
  kind: 'functionapp,linux,container'
  location: location
  
  properties: {
   enabled: true
    
    hostNameSslStates: [
      {
        name: '${ResourcePrefix}itdblobparser.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${ResourcePrefix}itdblobparser.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: serverFarm.id
    reserved: true
    isXenon: false
    hyperV: false
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'DOCKER|eidevcontainers.azurecr.io/itdazurefuncblobparser:20220306171150'
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 1
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: false
    redundancyMode: 'None'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

/*App Settings for Blob Parser*/

resource blobParserSettings 'Microsoft.Web/sites/config@2018-11-01' = {
  name: 'appsettings'
  kind: 'string'
  parent: ITDBlobParser
  properties: {
    AzureWebJobsStorage: blobStorageConnectionString
    DeleteOnProcessComplete: 'true'
    DiagnosticServices_EXTENSION_VERSION: '~3'
    EventHubCon: iotlistenauthrules.listKeys().primaryConnectionString
    FUNCTIONS_EXTENSION_VERSION: '~3'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: blobStorageConnectionString
    WEBSITE_CONTENTSHARE: 'itdblobparser97e3'
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
    DOCKER_CUSTOM_IMAGE_NAME: 'eidevcontainers.azurecr.io/itdazurefuncblobparser:20220306171150'
    DOCKER_REGISTRY_RESOURCE_ID: dockerRegistryResource_id
    DOCKER_REGISTRY_SERVER_PASSWORD: dockerRegistryServerPassword
    DOCKER_REGISTRY_SERVER_URL: dockerRegistryServerURL
    DOCKER_REGISTRY_SERVER_USERNAME: dockerRegistryServerUserName
  }
}




resource ITDIOTParser 'Microsoft.Web/sites@2021-03-01' = {
  name: '${ResourcePrefix}ITDIOTParser'
  kind: 'functionapp,linux,container'
  location: location
  
  properties: {
   enabled: true
   
    hostNameSslStates: [
      {
        name: '${ResourcePrefix}itdiotparser.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${ResourcePrefix}itdiotparser.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: serverFarm.id
    reserved: true
    isXenon: false
    hyperV: false
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'DOCKER|eidevcontainers.azurecr.io/itdazurefuncsiotmessageparser:20220323140400'
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 1
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: false
    redundancyMode: 'None'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

/*App Settings for IoT Parser*/
resource iotParserSettings 'Microsoft.Web/sites/config@2018-11-01' = {
  name: 'appsettings'
  kind: 'string'
  parent: ITDIOTParser
  properties: {
    AzureWebJobsStorage: blobStorageConnectionString
    DeleteOnProcessComplete: 'true'
    DiagnosticServices_EXTENSION_VERSION: '~3'
    EventHubCon: iotlistenauthrules.listKeys().primaryConnectionString
    EventHubOut: telemetrySendauthrules.listKeys().primaryConnectionString
    FUNCTIONS_EXTENSION_VERSION: '~3'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: blobStorageConnectionString
    WEBSITE_CONTENTSHARE: 'itdiotparserb794' 
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
    DOCKER_CUSTOM_IMAGE_NAME: 'eidevcontainers.azurecr.io/itdazurefuncsiotmessageparser:20220323140400'
    DOCKER_REGISTRY_RESOURCE_ID: dockerRegistryResource_id
    DOCKER_REGISTRY_SERVER_PASSWORD: dockerRegistryServerPassword
    DOCKER_REGISTRY_SERVER_URL: dockerRegistryServerURL
    DOCKER_REGISTRY_SERVER_USERNAME: dockerRegistryServerUserName
  
  }
}

/*ApplicationInsights*/

//todo - need to add config in AZ Funcs to hook into Appinsights.  This can be done manually right now after deployment

@description('Generated from /subscriptions/4753dce4-4462-4424-9529-c4653adadf81/resourceGroups/EIDev-Protos/providers/microsoft.insights/components/ITDFuncs')
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${ResourcePrefix}AppInsights'
  location: location
  kind: 'web'
    properties: {
    Application_Type: 'web'
    RetentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}
