param virtualNetworkName string
param subnetName string
@description('Specifies the function app resource name')
param resourceName string
param location string = resourceGroup().location
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: virtualNetworkName
}

resource site 'Microsoft.Web/sites@2023-12-01' existing = {
  name: resourceName
}

var sitesPrivateDNSZoneName = 'privatelink.azurewebsites.net'

// AVM module for Function App Private Endpoint with private DNS zone
module sitesPrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.11.0' = {
  name: 'sites-private-endpoint-deployment'
  params: {
    name: 'pep-${resourceName}'
    location: location
    tags: tags
    subnetResourceId: '${vnet.id}/subnets/${subnetName}'
    privateLinkServiceConnections: [
      {
        name: 'sitesPrivateLinkConnection'
        properties: {
          privateLinkServiceId: site.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
    customDnsConfigs: []
    // Creates private DNS zone and links
    privateDnsZoneGroup: {
      name: 'sitesPrivateDnsZoneGroup'
      privateDnsZoneGroupConfigs: [
        {
          name: 'sitesARecord'
          privateDnsZoneResourceId: privateDnsZoneSitesDeployment.outputs.resourceId
        }
      ]
    }
  }
}

// AVM module for Function App Private DNS Zone
module privateDnsZoneSitesDeployment 'br/public:avm/res/network/private-dns-zone:0.7.1' = {
  name: 'sites-private-dns-zone-deployment'
  params: {
    name: sitesPrivateDNSZoneName
    location: 'global'
    tags: tags
    virtualNetworkLinks: [
      {
        name: '${resourceName}-sites-link-${take(toLower(uniqueString(resourceName, virtualNetworkName)), 4)}'
        virtualNetworkResourceId: vnet.id
        registrationEnabled: false
        location: 'global'
        tags: tags
      }
    ]
  }
}
