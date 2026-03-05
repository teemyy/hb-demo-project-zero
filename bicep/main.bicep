targetScope = 'resourceGroup'

module hubVnet './modules/vnet.bicep' = {
  name: 'hubVnetDeployment1'
  params: {
    vnetName: 'vnet-hub-prod-01'
    vnetAddressPrefix: '10.30.0.0/16'
    subnetName: 'subnet-hub-prod-01'
    subnetAddressPrefix: '10.30.0.0/24'
  }
}

module spokeVnet1 './modules/vnet.bicep' = {
  name: 'spokeVnetDeployment1'
  params: {
    vnetName: 'vnet-spoke-prod-01'
    vnetAddressPrefix: '10.31.0.0/16'
    subnetName: 'subnet-spoke-prod-01'
    subnetAddressPrefix: '10.31.0.0/24'
  }
}


module spokeVnet2 './modules/vnet.bicep' = {
  name: 'spokeVnetDeployment2'
  params: {
    vnetName: 'vnet-spoke-prod-02'
    vnetAddressPrefix: '10.32.0.0/16'
    subnetName: 'subnet-spoke-prod-02'
    subnetAddressPrefix: '10.32.0.0/24'
  }
}
