param routeTableName string
param location string = resourceGroup().location
param firewallPrivateIp string

resource routeTable 'Microsoft.Network/routeTables@2024-01-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false 
    routes: [
      {
        name: 'route-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'         // ← all traffic
          nextHopType: 'VirtualAppliance'    // ← send to specific IP
          nextHopIpAddress: firewallPrivateIp // ← firewall private IP
        }
      }
    ]
  }
}

output routeTableId string = routeTable.id
