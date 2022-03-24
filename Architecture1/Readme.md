# Basic IoT Data Ingestion

This architectue is appropriate for users just getting started with IoT data as well as users who might have existing Azure Infrastructure and are looking for a minimal additon to that infrastrucutre to ingest data.

## Deployed Services

The following Services are deployed as part of this architecture Template:

* Azure IoT Hub
* Azure Storage Account

Azure IoT Hub will be configured to route all ingested data to Azure Storage.  For more information on IoT Hub message routing please see the following Microsoft documentation: [IoT Hub message Routing.](https://docs.microsoft.com/en-us/azure/iot-hub/iot-hub-devguide-messages-d2c)

## Deployment Parameters

The following parameters require input at the time of deployment:
|Parameter Name|Description|Default Value|
|--------------|-----------|-------------|
|Resource Group Name|Name of the grouping of resources.  Typically used to contain resources which will be managed together.|**None** - this must be provided|
|Resource Prefix|This prefix is attached to resources being created to assist with uniqueness.  For items such as Storage Accounts which require globally unique names other characters from the parent resource group name will also be used.|**None** - this must be provided|
|IoT Hub SKU|Size of the IoT Hub to be created.  Informatation about the various SKU types can be found here:  [IoT Hub Pricing](https://azure.microsoft.com/en-us/pricing/details/iot-hub/) - Note that this can be changed after deployment from the Azure Portal.|S1|
|IoT Hub Units|This refers to the number of instances of the IoT Hub SKU selected.  This value can also be edited from the Azure Portal.|1|

## Deploying this template

**Prerequisites**
* Installation of Azure CLI (this should include Bicep)

Clone the respository to your local machine then open a terminal and execute the following:

```bash
az deployment group create --resource-group ARMTestRG --template-file ./Architecture1/main.bicep --parameters ResourcePrefix=<prefix goes here> 

```

### Deploy via Azure Portal

To launch a Custom deployment of this template click the following link:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSandlerdev%2FARMTemplates%2Fmaster%2FArchitecture1%2Fmain.json%3Ftoken%3DGHSAT0AAAAAABRQQN27KUPO4Z27WJQTL6YWYR45VEA)
