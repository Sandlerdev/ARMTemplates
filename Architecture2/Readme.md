# IoT Data Ingestion with Time Series Analysis

This architectue is appropriate for users just getting started with IoT data as well as users who might have existing Azure Infrastructure and are looking for a minimal additon to that infrastrucutre to ingest data and perform ad-hoc analysis of Time Series Data.

Ingested data is routed to Time Series Insights where it is stored in both a Warm and Cold Storage.  The Warm Storage provides fast access to this data while cold storage provides low cost, long term storage of all collected data.  Further, all data in cold storage is stored as Parquet formated files, making them easy to query from popular Data Analysis tools.  

## Deployed Services

The following Services are deployed as part of this architecture Template:

* Azure IoT Hub
* Azure Storage Account
* Azure Time Series Insights
* Azure Time Series Insights Event Source

A new **Consumer Group** will be created in the IoT Hub and used by Time Series Insights (TSI).
TSI will be configured with the appropriate Time Series ID Property based on selection of the Data Source Parameter (see below).
TSI Event Source will be configured with the appropriate Time Stamp Property based on the selection of the Data Source Parameter (see below).

## Deployment Parameters

The following parameters require input at the time of deployment:
|Parameter Name|Description|Default Value|
|--------------|-----------|-------------|
|Resource Group Name|Name of the grouping of resources.  Typically used to contain resources which will be managed together.|**None** - this must be provided|
|Resource Prefix|This prefix is attached to resources being created to assist with uniqueness.  For items such as Storage Accounts which require globally unique names other characters from the parent resource group name will also be used.|**None** - this must be provided|
|IoT Hub SKU|Size of the IoT Hub to be created.  Informatation about the various SKU types can be found here:  [IoT Hub Pricing](https://azure.microsoft.com/en-us/pricing/details/iot-hub/) - Note that this can be changed after deployment from the Azure Portal.|S1|
|IoT Hub Units|This refers to the number of instances of the IoT Hub SKU selected.  This value can also be edited from the Azure Portal.|1|
|Data Source|As Time Series Insights only allows configuration of the Time Series ID property at creation time it is necessary to specify the source of data.|**ITD*** - Other options include OPCUA and FTEG|
|Warm Storage Duration|Number of Days to keep data in Warm Storage (up to 30 days). More information about TSI Storage can be found here: [Data Storage](https://docs.microsoft.com/en-us/azure/time-series-insights/concepts-storage) |7|

ITD* This solution assumes the use of the FileUpload IoT Edge Connector and assoicated Azure infrastructure (EventHub and various Azure Functions) only select this item if you are using this configuration. 

## Deploying this template

**Prerequisites**
* Installation of Azure CLI (this should include Bicep)

Clone the respository to your local machine then open a terminal and execute the following:

```bash
az deployment group create --resource-group ARMTestRG2 --template-file ./Architecture2/main.bicep --parameters ResourcePrefix=<prefix goes here>

```

### Deploy via Azure Portal

To launch a Custom deployment of this template click the following link:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSandlerdev%2FARMTemplates%2Fmaster%2FArchitecture1%2Fmain.json)
