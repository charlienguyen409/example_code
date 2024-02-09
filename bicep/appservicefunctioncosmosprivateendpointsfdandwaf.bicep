// Parameters (Ensure to provide values or set defaults for these parameters)  
param location string = 'East US' // example location, change as needed  
param appServicePlanSku string = 'P1v2' // example SKU, change as needed  
param cosmosDbAccountName string = 'yourcosmosdbaccount' // change as needed  
param vnetName string = 'yourVnetName' // change as needed  
param vnetAddressPrefix string = '10.0.0.0/16' // example address prefix, change as needed  
param subnet1Prefix string = '10.0.0.0/24' // example subnet prefix, change as needed  
param subnet2Prefix string = '10.0.1.0/24' // example subnet prefix, change as needed  
param appServiceName string = 'yourAppServiceName' // change as needed  
param functionName string = 'yourFunctionName' // change as needed  
param frontDoorName string = 'yourFrontDoorName' // change as needed    
param frontdoorwebapplicationfirewallpolicies_FrontDoorPremium_name string = 'FrontDoorPremium'

// Virtual Network and Subnets  
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' = {  
  name: vnetName  
  location: location  
  properties: {  
    addressSpace: {  
      addressPrefixes: [  
        vnetAddressPrefix  
      ]  
    }  
    subnets: [  
      {  
        name: 'AppServiceSubnet'  
        properties: {  
          addressPrefix: subnet1Prefix  
          privateEndpointNetworkPolicies: 'Disabled'  
          privateLinkServiceNetworkPolicies: 'Disabled'  
        }  
      }  
      {  
        name: 'CosmosDbSubnet'  
        properties: {  
          addressPrefix: subnet2Prefix  
          privateEndpointNetworkPolicies: 'Disabled'  
          privateLinkServiceNetworkPolicies: 'Disabled'  
        }  
      }  
    ]  
  }  
}  
  
// App Service Plan  
resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {  
  name: '${appServiceName}Plan'  
  location: location  
  properties: {  
    reserved: false  
    isXenon: false  
    hyperV: false  
  }  
  sku: {  
    name: appServicePlanSku  
    capacity: 1  
  }  
}  
  
// App Service  
resource appService 'Microsoft.Web/sites@2021-02-01' = {  
  name: appServiceName  
  location: location  
  properties: {  
    serverFarmId: appServicePlan.id  
    httpsOnly: true  
  }  
  // Add additional properties as needed  
}  
  
// App Service Private Endpoint  
resource appServicePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {  
  name: '${appServiceName}PrivateEndpoint'  
  location: location  
  properties: {  
    subnet: {  
      id: virtualNetwork.properties.subnets[0].id  
    }  
    privateLinkServiceConnections: [  
      {  
        name: '${appServiceName}PLSConnection'  
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
  
// Azure Function  
resource functionApp 'Microsoft.Web/sites@2021-02-01' = {  
  name: functionName  
  location: location  
  kind: 'functionapp'  
  properties: {  
    serverFarmId: appServicePlan.id  
    httpsOnly: true  
  }  
  // Add additional properties as needed  
}  
  
// Azure Function Private Endpoint  
resource functionAppPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {  
  name: '${functionName}PrivateEndpoint'  
  location: location  
  properties: {  
    subnet: {  
      id: virtualNetwork.properties.subnets[0].id  
    }  
    privateLinkServiceConnections: [  
      {  
        name: '${functionName}PLSConnection'  
        properties: {  
          privateLinkServiceId: functionApp.id  
          groupIds: [  
            'sites'  
          ]  
        }  
      }  
    ]  
  }  
}  
  
// Cosmos DB Account  
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-03-15' = {  
  name: cosmosDbAccountName  
  location: location  
  properties: {  
    databaseAccountOfferType: 'Standard'  
    // Add additional properties as needed  
  }  
}  
  
// Cosmos DB Private Endpoint  
resource cosmosDbPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {  
  name: '${cosmosDbAccountName}PrivateEndpoint'  
  location: location  
  properties: {  
    subnet: {  
      id: virtualNetwork.properties.subnets[1].id  
    }  
    privateLinkServiceConnections: [  
      {  
        name: '${cosmosDbAccountName}PLSConnection'  
        properties: {  
          privateLinkServiceId: cosmosDbAccount.id  
          groupIds: [  
            'Sql'  
          ]  
        }  
      }  
    ]  
  }  
}  
  
// VNet Peering (to another empty VNet)  
// resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-03-01' = {  
//   name: '${vnetName}/addPeering'  
//   properties: {  
//     remoteVirtualNetwork: {  
//       id: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{remoteVnetName}'  
//     }  
//     allowVirtualNetworkAccess: true  
//     allowForwardedTraffic: false  
//     allowGatewayTransit: false  
//     useRemoteGateways: false  
//   }  
// }  
  
// Azure Front Door with WAF  
resource frontDoor 'Microsoft.Network/frontDoors@2021-06-01' = {  
  name: frontDoorName  
  location: 'global'  
  properties: {  
    frontendEndpoints: [  
      {  
        name: 'defaultFrontendEndpoint'  
        properties: {  
          hostName: '${frontDoorName}.azurefd.net'  
          sessionAffinityEnabledState: 'Disabled'  
          webApplicationFirewallPolicyLink: {  
            id: frontdoorwebapplicationfirewallpolicies_FrontDoorPremium_name_resource.id  
          }  
        }  
      }  
    ]  
    backendPools: [  
      {  
        name: 'appServiceBackendPool'  
        properties: {  
          backends: [  
            {  
              address: appService.properties.defaultHostName  
              httpPort: 80  
              httpsPort: 443  
              priority: 1  
              weight: 50  
            }  
          ]  
          loadBalancingSettings: {  
            name: 'loadBalancingSettings1'  
          }  
          healthProbeSettings: {  
            name: 'healthProbeSettings1'  
          }  
        }  
      }  
    ]  
    // Add additional properties as needed  
  }  
}  
  
resource frontdoorwebapplicationfirewallpolicies_FrontDoorPremium_name_resource 'Microsoft.Network/frontdoorwebapplicationfirewallpolicies@2022-05-01' = {
  name: frontdoorwebapplicationfirewallpolicies_FrontDoorPremium_name
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
      redirectUrl: 'https://www.microsoft.com/en-us/edge'
      customBlockResponseStatusCode: 403
      customBlockResponseBody: 'QmxvY2tlZCBieSBGcm9udCBEb29yIFByZW1pdW0gV0FG'
      requestBodyCheck: 'Enabled'
    }
    customRules: {
      rules: [
        {
          name: 'RateLimitRequest'
          enabledState: 'Enabled'
          priority: 30
          ruleType: 'RateLimitRule'
          rateLimitDurationInMinutes: 1
          rateLimitThreshold: 1
          matchConditions: [
            {
              matchVariable: 'RequestUri'
              operator: 'Contains'
              negateCondition: false
              matchValue: [
                'search'
              ]
              transforms: []
            }
          ]
          action: 'Block'
        }
      ]
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
          ruleSetAction: 'Block'
          ruleGroupOverrides: []
          exclusions: []
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
          ruleGroupOverrides: []
          exclusions: []
        }
      ]
    }
  }
}
