param virtualNetworkGateways_vpngw_hub_prod_01_name string = 'vpngw-hub-prod-01'
param publicIPAddresses_pip_vpngw_hub_prod_01_externalid string = '/subscriptions/ff8de00d-5e23-498b-9ecf-03d4db265f5f/resourceGroups/rg-hub-prod-01/providers/Microsoft.Network/publicIPAddresses/pip-vpngw-hub-prod-01'
param virtualNetworks_vnet_hub_prod_01_externalid string = '/subscriptions/ff8de00d-5e23-498b-9ecf-03d4db265f5f/resourceGroups/rg-hub-prod-01/providers/Microsoft.Network/virtualNetworks/vnet-hub-prod-01'

resource virtualNetworkGateways_vpngw_hub_prod_01_name_resource 'Microsoft.Network/virtualNetworkGateways@2024-07-01' = {
  name: virtualNetworkGateways_vpngw_hub_prod_01_name
  location: 'swedencentral'
  tags: {
    hub: 'prod'
    infra: 'core'
  }
  properties: {
    enablePrivateIpAddress: false
    virtualNetworkGatewayMigrationStatus: {
      state: 'None'
      phase: 'None'
    }
    ipConfigurations: [
      {
        name: 'default'
        id: '${virtualNetworkGateways_vpngw_hub_prod_01_name_resource.id}/ipConfigurations/default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_pip_vpngw_hub_prod_01_externalid
          }
          subnet: {
            id: '${virtualNetworks_vnet_hub_prod_01_externalid}/subnets/GatewaySubnet'
          }
        }
      }
    ]
    natRules: []
    virtualNetworkGatewayPolicyGroups: []
    enableBgpRouteTranslationForNat: false
    disableIPSecReplayProtection: false
    sku: {
      name: 'VpnGw1AZ'
      tier: 'VpnGw1AZ'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: true
    enableHighBandwidthVpnGateway: false
    activeActive: false
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          '172.16.0.0/24'
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
      vpnAuthenticationTypes: [
        'AAD'
      ]
      vpnClientRootCertificates: []
      vpnClientRevokedCertificates: []
      vngClientConnectionConfigurations: []
      radiusServers: []
      vpnClientIpsecPolicies: []
      aadTenant: 'https://login.microsoftonline.com/362843e2-ccd8-43aa-bacf-4e81d4b02c4d/'
      aadAudience: '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
      aadIssuer: 'https://sts.windows.net/362843e2-ccd8-43aa-bacf-4e81d4b02c4d/'
    }
    bgpSettings: {
      asn: 65515
      bgpPeeringAddress: '10.30.0.30'
      peerWeight: 0
      bgpPeeringAddresses: [
        {
          ipconfigurationId: '${virtualNetworkGateways_vpngw_hub_prod_01_name_resource.id}/ipConfigurations/default'
          customBgpIpAddresses: []
        }
      ]
    }
    customRoutes: {
      addressPrefixes: []
    }
    vpnGatewayGeneration: 'Generation1'
    allowRemoteVnetTraffic: false
    allowVirtualWanTraffic: false
  }
}
