param location string = resourceGroup().location  
param vmName string = 'myVM'  
param adminUsername string = 'azureuser'  
param adminPassword string  
param vmSize string = 'Standard_DS1_v2'  
param scriptFileUri string // URL of the script to run on the VM  
  
// Generate a simple Windows VM  
resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-07-01' = {  
  name: vmName  
  location: location  
  properties: {  
    hardwareProfile: {  
      vmSize: vmSize  
    }  
    osProfile: {  
      computerName: vmName  
      adminUsername: adminUsername  
      adminPassword: adminPassword  
    }  
    storageProfile: {  
      imageReference: {  
        publisher: 'MicrosoftWindowsServer'  
        offer: 'WindowsServer'  
        sku: '2019-Datacenter'  
        version: 'latest'  
      }  
      osDisk: {  
        createOption: 'FromImage'  
        managedDisk: {  
          storageAccountType: 'Standard_LRS'  
        }  
      }  
    }  
    networkProfile: {  
      networkInterfaces: [  
        {  
          id: networkInterface.id  
        }  
      ]  
    }  
  }  
}  
  
// Network interface for the VM  
resource networkInterface 'Microsoft.Network/networkInterfaces@2021-05-01' = {  
  name: '${vmName}-nic'  
  location: location  
  properties: {  
    ipConfigurations: [  
      {  
        name: 'ipconfig1'  
        properties: {  
          subnet: {  
            id: subnet.id  
          }  
          privateIPAllocationMethod: 'Dynamic'  
        }  
      }  
    ]  
  }  
}  
  
// Virtual Network for the VM  
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {  
  name: '${vmName}-vnet'  
  location: location  
  properties: {  
    addressSpace: {  
      addressPrefixes: [  
        '10.0.0.0/16'  
      ]  
    }  
    subnets: [  
      {  
        name: 'default'  
        properties: {  
          addressPrefix: '10.0.0.0/24'  
        }  
      }  
    ]  
  }  
}  
  
// Subnet for the VM  
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {  
  name: '${virtualNetwork.name}/default'  
  properties: {}  
}  
  
// Custom Script Extension to configure the VM  
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {  
  name: '${vmName}/CustomScriptExtension'  
  location: location  
  properties: {  
    publisher: 'Microsoft.Compute'  
    type: 'CustomScriptExtension'  
    typeHandlerVersion: '1.10'  
    autoUpgradeMinorVersion: true  
    settings: {  
      fileUris: [scriptFileUri]  
    }  
    protectedSettings: {  
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File MyScript.ps1'  
    }  
  }  
}  
  
output vmId string = virtualMachine.id
