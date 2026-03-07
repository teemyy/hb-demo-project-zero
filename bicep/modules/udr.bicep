param routeTableName string
param location string = resourceGroup().location
param firewallPrivateIp string

resource routeTable 'Microsoft.Network/routeTables@2024-01-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false  // ← prevents VPN gateway routes
                                      //   overriding our custom routes
    routes: [
      {
        name: 'route-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'         // ← all traffic
          nextHopType: 'VirtualAppliance'    // ← send to specific IP
          nextHopIpAddress: firewallPrivateIp // ← firewall private IP
        }
        
      }
      {
    name: 'route-vpn-clients'          //routing for vpn clients
    properties: {
      addressPrefix: '172.16.0.0/24'   // vpn pool
      nextHopType: 'VirtualNetworkGateway'  //go via VPN gateway directly
    }
    }
    ]
  }
}

output routeTableId string = routeTable.id
