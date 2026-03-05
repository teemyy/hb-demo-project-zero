targetScope = 'subscription'
param location string = 'swedencentral'

// 1. Define the RGs
resource rgHub 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-hub-prod-01'
  location: location
}

resource rgSpoke1 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-spoke-prod-01'
  location: location
}

resource rgSpoke2 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-spoke-prod-02'
  location: location
}

//module for hub vnet
module hubVnet './modules/vnet.bicep' = {
  name: 'hubVnetDeployment1'
  scope: resourceGroup(rgHub.name)
  params: {
    vnetName: 'vnet-hub-prod-01'
    vnetAddressPrefix: '10.30.0.0/16'
    subnetName: 'subnet-hub-prod-01'
    subnetAddressPrefix: '10.30.0.0/24'
  }
}

//module for spoke1 vnet
module spokeVnet1 './modules/vnet.bicep' = {
  name: 'spokeVnetDeployment1'
  scope: resourceGroup(rgSpoke1.name)
  params: {
    vnetName: 'vnet-spoke-prod-01'
    vnetAddressPrefix: '10.31.0.0/16'
    subnetName: 'subnet-spoke-prod-01'
    subnetAddressPrefix: '10.31.0.0/24'
  }
}

//module for spoke2 vnet
module spokeVnet2 './modules/vnet.bicep' = {
  name: 'spokeVnetDeployment2'
  scope: resourceGroup(rgSpoke2.name)
  params: {
    vnetName: 'vnet-spoke-prod-02'
    vnetAddressPrefix: '10.32.0.0/16'
    subnetName: 'subnet-spoke-prod-02'
    subnetAddressPrefix: '10.32.0.0/24'
  }
}
