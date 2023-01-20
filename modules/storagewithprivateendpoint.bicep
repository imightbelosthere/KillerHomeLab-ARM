@description('This prefix will be used in combination with the Storage Account Number to create the Storage Account Name')
@maxLength(20)
param StorageAccountPrefix string = 'namethatequals23char'

@description('Private Endpoint Virtual Network')
param PrivateEndpointVnetName string = 'storage-VNet1'

@description('Private Endpoint Subnet Name')
param PrivateEndpointSubnetName string = 'storage-VNet1-Subnet1'

@description('Number of Storage Accounts that will be created.')
param NumberOfStorageAccountInstances int = 2

@description('Storage Accout Name Prefix Initial Number.')
param StorageAccountInitialNumber int = 1

@description('Target Sub Resource')
param GroupId array = [
  'blob'
]

@description('Private DNS Zone Name')
param PrivateDNSZoneName string = 'privatelink.blob.core.usgovcloudapi.net'

@description('Resource Group Location')
param location string = resourceGroup().location

var VNetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', PrivateEndpointVnetName)
var VirtualNetworkLinkName = '${PrivateDNSZoneName}/${PrivateEndpointVnetName}'
var subnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', PrivateEndpointVnetName, PrivateEndpointSubnetName)
var PrivateDNSZoneId = resourceId(resourceGroup().name, 'Microsoft.Network/privateDnsZones', PrivateDNSZoneName)

resource PrivateDNSZone_Resource 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: PrivateDNSZoneName
  location: 'global'
}

resource VirtualNetworkLink_Resource 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: VirtualNetworkLinkName
  location: 'global'
  properties: {
    virtualNetwork: {
      id: VNetId
    }
    registrationEnabled: true
  }
  dependsOn: [
    PrivateDNSZone_Resource
  ]
}

resource StorageAccount_Resource 'Microsoft.Storage/storageAccounts@2022-05-01' = [for i in range(0, NumberOfStorageAccountInstances): {
  name: '${StorageAccountPrefix}${(i + StorageAccountInitialNumber)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
  }
}]

resource StorageAccount_PrivateEndpoint_Resource 'Microsoft.Network/privateEndpoints@2022-05-01' = [for i in range(0, NumberOfStorageAccountInstances): {
  name: '${StorageAccountPrefix}${(i + StorageAccountInitialNumber)}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${StorageAccountPrefix}${(i + StorageAccountInitialNumber)}-pe'
        properties: {
          privateLinkServiceId: resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', '${StorageAccountPrefix}${(i + StorageAccountInitialNumber)}')
          groupIds: GroupId
        }
      }
    ]
  }
  dependsOn: [
    StorageAccount_Resource
  ]
}]

resource StorageAccount_PrivateEndpoint_DNSZone_Group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = [for i in range(0, NumberOfStorageAccountInstances): {
  name: '${StorageAccountPrefix}${(i + StorageAccountInitialNumber)}-pe/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: PrivateDNSZoneName
        properties: {
          privateDnsZoneId: PrivateDNSZoneId
        }
      }
    ]
  }
  dependsOn: [
    StorageAccount_PrivateEndpoint_Resource
    PrivateDNSZone_Resource
  ]
}]
