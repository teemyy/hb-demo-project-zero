targetScope = 'subscription'
param location string = 'swedencentral'

@secure()
param adminPassword string


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

// Gateway Route Table — must exist before hub VNet
module gatewayRouteTable './modules/udr-vpngw.bicep' = {
  name: 'gatewayRouteTableDeployment'
  scope: resourceGroup(rgHub.name)
  params: {
    routeTableName: 'rt-hub-gateway-prod-01'
    firewallPrivateIp: '10.30.1.4'
  }
}

//module for hub vnet
module hubVnet './modules/vnet.bicep' = {
  name: 'hubVnetDeployment1'
  scope: resourceGroup(rgHub.name)
  params: {
    vnetName: 'vnet-hub-prod-01'
    vnetAddressPrefix: '10.30.0.0/16'
    
     subnets: [
      {
        name: 'GatewaySubnet' // DO NOT CHANGE THIS NAME
        addressPrefix: '10.30.0.0/27'
        routeTableId: gatewayRouteTable.outputs.routeTableId
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.30.1.0/24'
      }
      {
    name: 'subnet-hub-prod-01'
    addressPrefix: '10.30.2.0/24'
     }
{
    name: 'AzureFirewallManagementSubnet'
    addressPrefix: '10.30.3.0/26'
     }
     
   ]
  } 
}
  


//peering for hubTospoke1
module hubToSpoke1 './modules/peering.bicep' = {
  name: 'hub-to-spoke1-peering'
  scope: resourceGroup(rgHub.name) 
  params: {
    localVnetName: hubVnet.outputs.vnetName
    remoteVnetId: spokeVnet1.outputs.vnetId
    peeringName: 'peer-hub-to-spoke01'
     allowGatewayTransit: true
  }
  dependsOn: [hubVpnGateway]
}
//peering for hubTospoke2
module hubToSpoke2 './modules/peering.bicep' = {
  name: 'hub-to-spoke2-peering'
  scope: resourceGroup(rgHub.name) 
  params: {
    localVnetName: hubVnet.outputs.vnetName
    remoteVnetId: spokeVnet2.outputs.vnetId
    peeringName: 'peer-hub-to-spoke02'
    allowGatewayTransit: true
  }

  // This ensures Hub is only updated by one peering at a time
  dependsOn: [hubToSpoke1 ]

}

/*module hubFirewall './modules/firewall.bicep' = {
  name: 'hubFirewallDeployment'
  scope: resourceGroup(rgHub.name)
  params: {
    firewallName: 'fw-hub-prod-01'
    publicIpName: 'pip-fw-hub-prod-01'
    managementPublicIpName: 'pip-fw-mgmt-hub-prod-01'
    vnetName: 'vnet-hub-prod-01'
    vnetResourceGroup: rgHub.name
    minecraftVmPrivateIp: '10.31.0.4'
  }
  dependsOn: [hubVnet]
}
*/

// VPN Gateway
module hubVpnGateway './modules/vpngateway.bicep' = {
  name: 'hubVpnGatewayDeployment'
  scope: resourceGroup(rgHub.name)
  params: {
    gatewayName: 'vpngw-hub-prod-01'
    publicIpName: 'pip-vpngw-hub-prod-01'
    vnetName: 'vnet-hub-prod-01'
    vnetResourceGroup: rgHub.name
    tenantId: '362843e2-ccd8-43aa-bacf-4e81d4b02c4d'
  }
  dependsOn: [hubVnet]
}

// NSG for Spoke1
module spoke1NSG './modules/nsg.bicep' = {
  name: 'spoke1NSGDeployment'
  scope: resourceGroup(rgSpoke1.name)
  params: {
    nsgName: 'nsg-spoke-prod-01'
  }
}

// Route table for Spoke1
module spoke1RouteTable './modules/udr.bicep' = {
  name: 'spoke1RouteTableDeployment'
  scope: resourceGroup(rgSpoke1.name)
  params: {
    routeTableName: 'rt-spoke-prod-01'
    firewallPrivateIp: '10.30.1.4'
  }
}

//module for spoke1 vnet
module spokeVnet1 './modules/vnet.bicep' = {
  name: 'spokeVnetDeployment1'
  scope: resourceGroup(rgSpoke1.name)
  params: {
    vnetName: 'vnet-spoke-prod-01'
    vnetAddressPrefix: '10.31.0.0/16'
    subnets: [
    {
      name: 'subnet-spoke-prod-01'
      addressPrefix: '10.31.0.0/24'
      nsgId: spoke1NSG.outputs.nsgId
      routeTableId: spoke1RouteTable.outputs.routeTableId
    }
  ] 
  }
}

//vm for spoke1
module spoke1VM './modules/vm.bicep' = {
  name: 'spoke1VMDeployment'
  scope: resourceGroup(rgSpoke1.name)
  params: {
    vmName: 'vm-spoke1-prod-01'
    subnetId: spokeVnet1.outputs.subnetRefs[0].id 
    adminUsername: 'azureuser'
    adminPassword: adminPassword
  }
}

//peering for spoke1
module Spoke1toHub './modules/peering.bicep' = {
  name: 'spoke01-to-hub-peering'
  scope: resourceGroup(rgSpoke1.name) 
  params: {
    localVnetName: spokeVnet1.outputs.vnetName
    remoteVnetId: hubVnet.outputs.vnetId
    peeringName: 'peer-spoke01-to-hub'
    useRemoteGateways: true
  }
  dependsOn: [hubToSpoke1, hubVpnGateway]
}


module spoke2NSG './modules/nsg.bicep' = {
  name: 'spoke2NSGDeployment'
  scope: resourceGroup(rgSpoke2.name)
  params: {
    nsgName: 'nsg-spoke-prod-02'
  }
}

//module for spoke2 vnet
module spokeVnet2 './modules/vnet.bicep' = {
  name: 'spokeVnetDeployment2'
  scope: resourceGroup(rgSpoke2.name)
  params: {
    vnetName: 'vnet-spoke-prod-02'
    vnetAddressPrefix: '10.32.0.0/16'
   subnets: [
    {
      name: 'subnet-spoke-prod-02'
      addressPrefix: '10.32.0.0/24'
      nsgId: spoke2NSG.outputs.nsgId
    }
  ] 
  }
}
//peering for spoke2
module spoke2toHub './modules/peering.bicep' = {
  name: 'spoke02-to-hub-peering'
  scope: resourceGroup(rgSpoke2.name) 
  params: {
    localVnetName: spokeVnet2.outputs.vnetName
    remoteVnetId: hubVnet.outputs.vnetId
    peeringName: 'peer-spoke02-to-hub'
    useRemoteGateways: true      
  }
  dependsOn: [hubToSpoke2, hubVpnGateway]
}

//vm for spoke2
module spoke2VM './modules/vm.bicep' = {
  name: 'spoke2VMDeployment'
  scope: resourceGroup(rgSpoke2.name)
  params: {
    vmName: 'vm-spoke2-prod-02'
    subnetId: '/subscriptions/ff8de00d-5e23-498b-9ecf-03d4db265f5f/resourceGroups/rg-spoke-prod-02/providers/Microsoft.Network/virtualNetworks/vnet-spoke-prod-02/subnets/subnet-spoke-prod-02' 
    adminUsername: 'azureuser'
    adminPassword: adminPassword
  }
}

