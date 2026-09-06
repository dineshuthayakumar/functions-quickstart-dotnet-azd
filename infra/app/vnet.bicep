@description('Specifies the name of an existing virtual network to integrate with.')
param vNetName string

@description('Specifies the name of the subnet for the Function App private endpoint.')
param peSubnetName string = 'snet-private-endpoints'

@description('Specifies the address prefix for the private endpoint subnet. Must not overlap with existing subnets in the VNet.')
param peSubnetAddressPrefix string = '10.10.3.0/24'

@description('Specifies the name of the subnet for Function App virtual network integration.')
param appSubnetName string = 'snet-func-app'

@description('Specifies the address prefix for the Function App subnet. Must not overlap with existing subnets in the VNet.')
param appSubnetAddressPrefix string = '10.10.2.0/24'

// Reference the existing (shared) virtual network - do NOT redeclare its address space/subnets,
// as that would replace the whole subnets collection and remove pre-existing subnets.
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vNetName
}

// Additive subnet for the storage account private endpoint (inbound)
resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: peSubnetName
  properties: {
    addressPrefix: peSubnetAddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

// Additive subnet for Function App VNet integration (outbound), delegated per Flex Consumption requirements
resource appSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: appSubnetName
  properties: {
    addressPrefix: appSubnetAddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
  }
  dependsOn: [
    peSubnet // serialize subnet writes to avoid concurrent-PUT conflicts on the same VNet
  ]
}

output vnetId string = vnet.id
output peSubnetName string = peSubnetName
output peSubnetID string = peSubnet.id
output appSubnetName string = appSubnetName
output appSubnetID string = appSubnet.id
