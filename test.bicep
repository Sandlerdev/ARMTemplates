
@description('Generated from /subscriptions/4753dce4-4462-4424-9529-c4653adadf81/resourceGroups/EIDev-Protos/providers/Microsoft.TimeSeriesInsights/environments/ITD-TSI-Proto/eventsources/itdtsieventhub')
resource itdtsieventhub 'Microsoft.TimeSeriesInsights/environments/eventSources@2020-05-15' = {
  kind: 'Microsoft.EventHub'
  location: 'eastus'
 
  properties: {
    eventSourceResourceId: '/subscriptions/4753dce4-4462-4424-9529-c4653adadf81/resourceGroups/EIDev-Protos/providers/Microsoft.EventHub/namespaces/EIProtoDevEventHub/eventhubs/telemetrydata'
    eventHubName: 'telemetrydata'
    serviceBusNamespace: 'EIProtoDevEventHub'
    consumerGroupName: 'tsieventhub'
    keyName: 'TSI'
    timestampPropertyName: 'body.gatewayData.vqts.t'
    ingressStartAt: {
      type: 'EventSourceCreationTime'
    }
    provisioningState: 'Succeeded'
  }
  name: 'ITD-TSI-Proto/itdtsieventhub'
}
