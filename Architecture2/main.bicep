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
param DataSource string = 'ITD'

@minValue(0)
@maxValue(30)
@description('Select the number of days to hold TSI data in warm storage.  Valid values between 0 and 30.')
param WarmStorageDuration int = 7

var blobStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${IoTStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(IoTStorage.id, IoTStorage.apiVersion).keys[0].value}'
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

//used when routing IoT Data to Storage.
// resource telemetryContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
//   name: 'telemetrydata'
//   parent: blobServices
//   properties:{
//     publicAccess: 'None'

//   }

// }

resource IoTHub 'Microsoft.Devices/IotHubs@2021-07-02'= {
  name: '${ResourcePrefix}-IoTHub'
  location: location
  sku:{
    name: IoTHubSKU
    capacity: IoTHubUnits
    
  }
  properties:{
    // routing: {
    //   endpoints: {
        
    //     storageContainers: [
    //       {
    //         connectionString: blobStorageConnectionString
    //         containerName: 'telemetrydata'
    //         fileNameFormat: '{iothub}/{partition}/{YYYY}/{MM}/{DD}/{HH}/{mm}.avro'
    //         encoding: 'JSON'
    //         name: 'telemetrydata'
    //       }
    //     ]
      
    // }
  
    //   routes: [
    //     {
    //       name: 'sendToStorageAccount'
    //       source: 'DeviceMessages'
    //       condition: 'true'
    //       endpointNames: [
    //         'telemetrydata'
    //       ]
    //       isEnabled: true
    //     }
    //   ]
    // }
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
  name: TSIConsumerGroupName
  properties:{
    name: 'TSI'
  }
}


//TSI Event Source

//TSI

