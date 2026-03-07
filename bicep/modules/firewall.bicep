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

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-01-01' = {
  name: '${firewallName}-policy'
  location: location
  sku: { name: 'Basic', tier: 'Basic' }
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
        action: { type: 'DNAT' }
        rules: [
          {
            ruleType: 'NatRule'
            name: 'forward-minecraft-java'
            ipProtocols: ['TCP']
            sourceAddresses: ['*']
            destinationAddresses: [publicIp.properties.ipAddress]
            destinationPorts: ['25565']
            translatedAddress: minecraftVmPrivateIp
            translatedPort: '25565'
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'minecraft-network-rules'
        priority: 200
        action: { type: 'Allow' }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-minecraft-to-spoke1'
            ipProtocols: ['TCP']
            sourceAddresses: ['*']
            destinationAddresses: [minecraftVmPrivateIp]
            destinationPorts: ['25565']
          }
          {
            ruleType: 'NetworkRule'
            name: 'allow-ssh-from-vpn'
            ipProtocols: ['TCP']
            sourceAddresses: ['172.16.0.0/24']
            destinationAddresses: [minecraftVmPrivateIp]
            destinationPorts: ['22']
          }
        ]
      }
    ]
  }
}

resource networkRuleCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-01-01' = {
  name: 'DefaultNetworkRuleCollectionGroup'
  parent: firewallPolicy
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'spoke-MINECRAFT-to-world'
        priority: 250
        action: { type: 'Allow' }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'spoke-auth-to-minecraft'
            ipProtocols: ['Any']
            sourceAddresses: ['10.31.0.0/24']
            destinationAddresses: ['*']
            destinationPorts: ['443']
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'vpn-to-spoke-rules'
        priority: 300
        action: { type: 'Allow' }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-icmp-from-vpn'
            ipProtocols: ['Any']
            sourceAddresses: ['172.16.0.0/24']
            destinationAddresses: ['10.31.0.0/24']
            destinationPorts: ['*']
          }
          {
            ruleType: 'NetworkRule'
            name: 'allow-ssh-from-vpn'
            ipProtocols: ['TCP']
            sourceAddresses: ['172.16.0.0/24']
            destinationAddresses: ['10.31.0.4']
            destinationPorts: ['22']
          }
          {
            ruleType: 'NetworkRule'
            name: 'allow-spoke-to-vpn-return'
            ipProtocols: ['Any']
            sourceAddresses: ['10.31.0.0/16']
            destinationAddresses: ['172.16.0.0/24']
            destinationPorts: ['*']
          }
        ]
      }
    ]
  }
  dependsOn: [dnatRuleCollection]
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
  dependsOn: [dnatRuleCollection, networkRuleCollection]
}

output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPublicIp string = publicIp.properties.ipAddress
