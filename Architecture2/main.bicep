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

var blobStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${IoTStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(IoTStorage.id, IoTStorage.apiVersion).keys[0].value}'
var iotHubOnwerKey = IoTHub.listkeys().value
//output iothubOnwerKeyOut string = iotHubOnwerKey[0].primaryKey
var eventSourceName = '${TSIEVN.name}/${ResourcePrefix}EventSource'
//output eventSoruceNameOut string = eventSourceName
var IoTHubName = '${ResourcePrefix}IoTHub'
var TSIConsumerGroupName = '${IoTHub.name}/events/TSI'

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


resource TSIConsumerGroup 'Microsoft.Devices/IotHubs/eventHubEndpoints/ConsumerGroups@2021-07-02' = {
  name: TSIConsumerGroupName //'ab2IoTHub/events/TSI' 
  properties:{
    name: 'TSI'

  }
}

resource TSIES 'Microsoft.TimeSeriesInsights/environments/eventSources@2020-05-15' = {
  kind: 'Microsoft.IoTHub'
  location: location
 
  properties: {
    sharedAccessKey: iotHubOnwerKey[0].primaryKey
    eventSourceResourceId: IoTHub.id   
    iotHubName: IoTHub.name
    consumerGroupName: TSIConsumerGroup.name
    keyName:'iothubowner'
    timestampPropertyName: 'gatewayData.vqts.t'

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
        name: 'iothub-connection0device-id'
        type: 'String'
      }
      {
        name: 'gatewayData.model_id'
        type: 'String'
      }
    ]
    warmStoreConfiguration: {
      dataRetention: 'P7D'
    }
  }
  name: '${ResourcePrefix}TSI'
}
