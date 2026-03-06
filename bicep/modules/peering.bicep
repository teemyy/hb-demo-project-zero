param localVnetName string
param remoteVnetId string
param peeringName string
param allowGatewayTransit bool = false
param useRemoteGateways bool = false    


resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${localVnetName}/${peeringName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
       id: remoteVnetId
    }
  }
}
