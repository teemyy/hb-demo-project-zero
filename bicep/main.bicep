targetScope = 'resourceGroup'

module hubVnet './modules/vnet.bicep' = {
  name: 'hubVnetDeployment'
  params: {
    vnetName: 'vnet-hub-prod-01'
    vnetAddressPrefix: '10.30.0.0/16'
    subnetName: 'subnet-hub-prod-01'
    subnetAddressPrefix: '10.30.0.0/24'
  }
}

module spokeVnet './modules/vnet.bicep' = {
  name: 'spokeVnetDeployment'
  params: {
    vnetName: 'vnet-spoke-prod-01'
    vnetAddressPrefix: '10.31.0.0/16'
    subnetName: 'subnet-spoke-prod-01'
    subnetAddressPrefix: '10.31.0.0/24'
  }
}
