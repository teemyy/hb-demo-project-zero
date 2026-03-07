param location string = resourceGroup().location
param firewallName string
param publicIpName string
param vnetName string
param vnetResourceGroup string
param minecraftVmPrivateIp string   // VM to forward traffic to
param managementPublicIpName string




resource publicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' existing = {
  name: publicIpName
  
}

resource managementPublicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' existing = {
  name: managementPublicIpName
}



resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-01-01' = {
  name: '${firewallName}-policy'
  location: location
  properties: {
    sku: {
    tier: 'Basic'                    //cheapest tier
  }
}
}

resource dnatRuleCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-01-01' = {
  name: 'DefaultDnatRuleCollectionGroup'
  parent: firewallPolicy
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        name: 'minecraft-dnat-rules'
        priority: 100
        action: {
          type: 'DNAT'               //translate destination
        }
        rules: [
          {
            ruleType: 'NatRule'
            name: 'forward-minecraft-java'
            ipProtocols: ['TCP']
            sourceAddresses: ['*']   // ← allow from anywhere
            destinationAddresses: [publicIp.properties.ipAddress]
            destinationPorts: ['25565']
            translatedAddress: minecraftVmPrivateIp  // ← forward to VM
            translatedPort: '25565'
          }
        ]
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2024-01-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
    name: 'AZFW_VNet'
    tier: 'Basic'
  }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'fw-ipconfig'
        properties: {
          subnet: {
            id: resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureFirewallSubnet')
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    managementIpConfiguration: {        // ← add this entire block
      name: 'fw-mgmt-ipconfig'
      properties: {
        subnet: {
          id: resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureFirewallManagementSubnet')
        }
        publicIPAddress: {
          id: managementPublicIp.id
        }
      }
    }
  }
  dependsOn: [dnatRuleCollection]
}

output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPublicIp string = publicIp.properties.ipAddress

