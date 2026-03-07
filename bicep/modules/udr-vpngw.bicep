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
        name: 'route-spoke1-via-firewall'
        properties: {
          addressPrefix: '10.31.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

output routeTableId string = routeTable.id
