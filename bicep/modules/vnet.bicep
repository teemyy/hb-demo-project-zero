param vnetName string
param vnetAddressPrefix string
param location string = resourceGroup().location // Defaults to the RG's location
param subnets array = []

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: vnetName
  location: location
  tags: {
    hub: 'prod'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    privateEndpointVNetPolicies: 'Disabled'

    subnets: [for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefixes: [
            subnet.addressPrefix
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}
output vnetId string = vnetName_resource.id
output vnetName string = vnetName_resource.name
output subnetRefs array = vnetName_resource.properties.subnets
