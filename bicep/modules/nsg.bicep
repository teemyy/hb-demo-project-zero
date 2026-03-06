param nsgName string
param location string = resourceGroup().location

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh_for_vpn'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '172.16.0.0/24'  // only VPN clients
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'             // SSH port
        }
      }
      {
        name: 'ICMP_for_vpn'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Icmp'
          sourceAddressPrefix: '172.16.0.0/24'  // only VPN clients
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'Allow-Minecraft-from-VPN'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '172.16.0.0/24'  // only VPN clients
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '25565'          // Minecraft default port
        }
      }
      
{
        name: 'Allow-Minecraft-from-VPN-def2'
        properties: {
          priority: 130
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Udp'
          sourceAddressPrefix: '172.16.0.0/24'  // only VPN clients
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '19132'          // Minecraft default port
        }
      }

      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

output nsgId string = nsg.id
