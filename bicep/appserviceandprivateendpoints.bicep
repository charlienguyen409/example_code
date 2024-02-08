param location string = 'eastus'  
param appServicePlanName string = 'myAppServicePlan'  
param appServiceName string = 'myAppService'  
param vnetName string = 'myVnetc'  
param subnetName string = 'mySubnet'  
param privateEndpointName string = 'myPrivateEndpoint'  
  
// App Service Plan  
resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {  
  name: appServicePlanName  
  location: location  
  sku: {  
    name: 'P1v2' // Pricing tier of the App Service Plan  
  }  
  kind: 'app'  
  properties: {}  
}  
  
// App Service  
resource appService 'Microsoft.Web/sites@2020-06-01' = {  
  name: appServiceName  
  location: location  
  kind: 'app'  
  properties: {  
    serverFarmId: appServicePlan.id  
    httpsOnly: true  
  }  
  identity: {  
    type: 'SystemAssigned'  
  }  
}  
  
// Virtual Network and Subnet for Private Endpoint  
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {  
  name: vnetName  
  location: location  
  properties: {  
    addressSpace: {  
      addressPrefixes: [  
        '10.0.0.0/16'  
      ]  
    }  
    subnets: [  
      {  
        name: subnetName  
        properties: {  
          addressPrefix: '10.0.1.0/24'  
          privateEndpointNetworkPolicies: 'Disabled' // Required to allow Private Endpoints  
        }  
      }  
    ]  
  }  
}  
  
// Private Endpoint  
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {  
  name: privateEndpointName  
  location: location  
  properties: {  
    subnet: {  
      id: vnet.properties.subnets[0].id  
    }  
    privateLinkServiceConnections: [  
      {  
        name: '${appServiceName}-connection'  
        properties: {  
          privateLinkServiceId: appService.id  
          groupIds: [  
            'sites'  
          ]  
        }  
      }  
    ]  
  }  
}  
  
// Outputs  
output appServiceUrl string = appService.properties.defaultHostName  
output privateEndpointId string = privateEndpoint.id
