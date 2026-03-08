param location string = resourceGroup().location
param firewallName string
param publicIpName string
param vnetName string
param vnetResourceGroup string
param minecraftVmPrivateIp string
param managementPublicIpName string

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' existing = {
  name: publicIpName
}

resource managementPublicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' existing = {
  name: managementPublicIpName
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-01-01' existing = {
  name: '${firewallName}-policy'
}

resource firewall 'Microsoft.Network/azureFirewalls@2024-01-01' = {
  name: firewallName
  location: location
  properties: {
    sku: { name: 'AZFW_VNet', tier: 'Basic' }
    firewallPolicy: { id: firewallPolicy.id }
    ipConfigurations: [
      {
        name: 'fw-ipconfig'
        properties: {
          subnet: {
            id: resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureFirewallSubnet')
          }
          publicIPAddress: { id: publicIp.id }
        }
      }
    ]
    managementIpConfiguration: {
      name: 'fw-mgmt-ipconfig'
      properties: {
        subnet: {
          id: resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureFirewallManagementSubnet')
        }
        publicIPAddress: { id: managementPublicIp.id }
      }
    }
  }
}

output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPublicIp string = publicIp.properties.ipAddress
