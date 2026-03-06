param location string = resourceGroup().location
param vmName string
param subnetId string        
param adminUsername string

@secure()                    // tells Azure: never log this value
param adminPassword string


resource publicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  
   name: '${vmName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'  
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId         // plugs into Spoke1's subnet
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id      // attaches the public IP
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'   // ← 2 vCPU, 4GB RAM
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'  // ← Ubuntu 22.04 LTS
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'  
        }
        diskSizeGB: 32           
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id             //  connects to the NIC we made above
        }
      ]
    }
  }
}

resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'  
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '2200'             // ← 22:00 UTC = midnight Finland time
    }
    timeZoneId: 'UTC'
    targetResourceId: vm.id
  }
}

output vmName string = vm.name
output publicIpAddress string = publicIp.properties.ipAddress
