param location string = resourceGroup().location
param gatewayName string
param publicIpName string
param vnetName string
param vnetResourceGroup string
param vpnClientAddressPool string = '172.16.0.0/24'
param tenantId string
param audience string = '41b23e61-6c1e-4545-b367-cd054e0ed4b4'

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' existing = {
  name: publicIpName
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2024-01-01' = {
  name: gatewayName
  location: location
  properties: {
    enablePrivateIpAddress: true
    sku: { name: 'VpnGw1AZ', tier: 'VpnGw1AZ' }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: publicIp.id }
          subnet: {
            id: resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, 'GatewaySubnet')
          }
        }
      }
    ]
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [ vpnClientAddressPool ]
      }
      vpnClientProtocols: [ 'OpenVPN' ]
      vpnAuthenticationTypes: [ 'AAD' ]
      aadTenant: 'https://login.microsoftonline.com/${tenantId}/'
      aadAudience: audience
      aadIssuer: 'https://sts.windows.net/${tenantId}/'
    }
  }
}

output gatewayId string = vpnGateway.id
output gatewayName string = vpnGateway.name
