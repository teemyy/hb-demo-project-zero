// ── STANDALONE FIREWALL DEPLOYMENT ──
// Deploy with:
// az deployment group create --resource-group rg-hub-prod-01 --template-file firewall.bicep

param location string = resourceGroup().location
param firewallName string = 'fw-hub-prod-01'
param policyName string = 'fw-policy-hub-prod-01'
param publicIpName string = 'pip-fw-hub-prod-01'
param managementPublicIpName string = 'pip-fw-mngm-hub-prod-01'
param vnetName string = 'vnet-hub-prod-01'
param vnetResourceGroup string = 'rg-hub-prod-01'

// Firewall public IP (must already exist, zone-redundant Standard)
resource publicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' existing = {
  name: publicIpName
}

// Firewall management public IP (must already exist, zone-redundant Standard)
resource managementPublicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' existing = {
  name: managementPublicIpName
}

// ── FIREWALL POLICY ──
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-01-01' = {
  name: policyName
  location: location
  properties: {
    sku: {
      tier: 'Basic'
    }
  }
}

// ── RULE COLLECTION GROUP: DNAT (priority 100) ──
resource dnatRuleGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-01-01' = {
  name: 'DefaultDnatRuleCollectionGroup'
  parent: firewallPolicy
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        name: 'minecraft-dnat'
        priority: 100
        action: { type: 'Dnat' }
        rules: [
          {
            ruleType: 'NatRule'
            name: 'forward-minecraft-java'
            ipProtocols: [ 'TCP' ]
            sourceAddresses: [ '*' ]
            destinationAddresses: [ '4.223.64.164' ]  // firewall public IP
            destinationPorts: [ '25565' ]
            translatedAddress: '10.31.0.4'            // Spoke1 VM
            translatedPort: '25565'
          }
        ]
      }
    ]
  }
}

// ── RULE COLLECTION GROUP: NETWORK (priority 200) ──
resource networkRuleGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-01-01' = {
  name: 'DefaultNetworkRuleCollectionGroup'
  parent: firewallPolicy
  properties: {
    priority: 200
    ruleCollections: [
      {
        // Spoke1 outbound internet — needed for Minecraft auth against Mojang
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'minecraft-authentication'
        priority: 400
        action: { type: 'Allow' }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-spoke1-to-internet'
            ipProtocols: [ 'TCP' ]
            sourceAddresses: [ '10.31.0.4' ]
            destinationAddresses: [ '*' ]
            destinationPorts: [ '*' ]
          }
        ]
      }
      {
        // Spoke2 ping check → Spoke1 and return
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'spoke2-to-spoke1'
        priority: 500
        action: { type: 'Allow' }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-spoke2-icmp-to-spoke1'
            ipProtocols: [ 'ICMP' ]
            sourceAddresses: [ '10.32.0.0/24' ]
            destinationAddresses: [ '10.31.0.0/24' ]
            destinationPorts: [ '*' ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'allow-spoke1-icmp-to-spoke2'
            ipProtocols: [ 'ICMP' ]
            sourceAddresses: [ '10.31.0.0/24' ]
            destinationAddresses: [ '10.32.0.0/24' ]
            destinationPorts: [ '*' ]
          }
        ]
      }
    ]
  }
  dependsOn: [dnatRuleGroup] // rule collection groups must be deployed sequentially
}

// ── RULE COLLECTION GROUP: VPN (priority 300) ──
resource vpnRuleGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-01-01' = {
  name: 'vpn-to-spoke-rules'
  parent: firewallPolicy
  properties: {
    priority: 300
    ruleCollections: [
      {
        // VPN client ↔ Spoke1 bidirectional
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'vpn-to-spoke'
        priority: 300
        action: { type: 'Allow' }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-vpn-to-spoke1'
            ipProtocols: [ 'Any' ]
            sourceAddresses: [ '172.16.0.0/24' ]
            destinationAddresses: [ '10.31.0.0/16' ]
            destinationPorts: [ '*' ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'allow-spoke1-to-vpn'
            ipProtocols: [ 'Any' ]
            sourceAddresses: [ '10.31.0.0/16' ]
            destinationAddresses: [ '172.16.0.0/24' ]
            destinationPorts: [ '*' ]
          }
        ]
      }
      {
        // VPN client → Spoke2 web (port 80)
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'allow-vpn-to-spoke2'
        priority: 500
        action: { type: 'Allow' }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-vpn-to-spoke2'
            ipProtocols: [ 'TCP' ]
            sourceAddresses: [ '172.16.0.0/24' ]
            destinationAddresses: [ '10.32.0.4' ]
            destinationPorts: [ '80' ]
          }
        ]
      }
    ]
  }
  dependsOn: [networkRuleGroup] // rule collection groups must be deployed sequentially
}

// ── FIREWALL ──
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
  dependsOn: [vpnRuleGroup]
}

output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPublicIp string = publicIp.properties.ipAddress
