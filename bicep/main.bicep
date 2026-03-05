targetScope = 'subscription'
param location string = 'swedencentral'
//deployment command->  az deployment sub create --location swedencentral --template-file main.bicep

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

module hubToSpoke1 './modules/peerings.bicep' = {
  name: 'hub-to-spoke1-peering'
  scope: resourceGroup(rgHub.name) 
  params: {
    localVnetName: 'vnet-hub-prod-01'
    remoteVnetId: spokeVnet1.outputs.vnetId
    peeringName: 'peer-hub-to-spoke01'
  }
}

module hubToSpoke2 './modules/peerings.bicep' = {
  name: 'hub-to-spoke2-peering'
  scope: resourceGroup(rgHub.name) 
  params: {
    localVnetName: 'vnet-hub-prod-01'
    remoteVnetId: spokeVnet2.outputs.vnetId
    peeringName: 'peer-hub-to-spoke02'
  }

  // This ensures Hub is only updated by one peering at a time
  dependsOn: [
    hubToSpoke1
  ]

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

//peering for spoke1
module Spoke1toHub './modules/peerings.bicep' = {
  name: 'spoke01-to-hub-peering'
  scope: resourceGroup(rgSpoke1.name) 
  params: {
    localVnetName: 'vnet-spoke-prod-01'
    remoteVnetId: hubVnet.outputs.vnetId
    peeringName: 'peer-spoke01-to-hub'
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
//peering for spoke2
module spoke2toHub './modules/peerings.bicep' = {
  name: 'spoke02-to-hub-peering'
  scope: resourceGroup(rgSpoke2.name) 
  params: {
    localVnetName: 'vnet-spoke-prod-02'
    remoteVnetId: hubVnet.outputs.vnetId
    peeringName: 'peer-spoke02-to-hub'
  }
}
