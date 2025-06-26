param location string
param subscriptionId string
param resourceGroupName string
param vnetName string
param subnetName string
param networkSettingsName string
param databaseId string

var subnetResourceId = resourceId(
  subscriptionId,
  resourceGroupName,
  'Microsoft.Network/virtualNetworks/subnets',
  vnetName,
  subnetName
)

resource networkSettings 'GitHub.Network/networkSettings@2024-04-02' = {
  name: networkSettingsName
  location: location
  properties: {
    subnetId: subnetResourceId
    businessId: databaseId
  }
}
