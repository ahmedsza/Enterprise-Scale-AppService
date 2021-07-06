// Parameters
@description('A short name for the workload being deployed')
param workloadName string

@description('Azure location to which the resources are to be deployed, defaulting to the resource group location')
param location string

@description('The environment for which the deployment is being executed')
@allowed([
  'dev'
  'uat'
  'prod'
  'dr'
])
param environment string

param hubVNetNameAddressPrefix string = '10.0.0.0/16'
param spokeVNetNameAddressPrefix string = '10.1.0.0/16'

param bastionAddressPrefix string = '10.0.1.0/24'
param devOpsNameAddressPrefix string = '10.0.2.0/24'
param jumpBoxAddressPrefix string = '10.0.3.0/24'

param aseAddressPrefix string = '10.1.1.0/24'

@description('Name of the Bastion Subnet')
param bastionSubnetName string

@description('Name of the DevOps Subnet')
param devOpsSubnetName string

@description('Name of the JumpBox Subnet')
param jumpBoxSubnetName string

@description('Name of the ASEv3 Subnet')
param aseSubnetName string

// Variables
var owner = 'ASE Const Set'
var hubVNetName = 'vnet-hub-${workloadName}-${environment}-${location}'
var spokeVNetName = 'vnet-spoke-${workloadName}-${environment}-${location}-001'

// Resources - VNet - SubNets
resource vnetHub 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: hubVNetName
  location: resourceGroup().location
  tags: {
    Owner: owner
    // CostCenter: costCenter
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVNetNameAddressPrefix
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: [
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionAddressPrefix
        }
      }
      {
        name: devOpsSubnetName
        properties: {
          addressPrefix: devOpsNameAddressPrefix
        }
      }
      {
        name: jumpBoxSubnetName
        properties: {
          addressPrefix: jumpBoxAddressPrefix
        }
      }
    ]
  }
}

// resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
//   name: bastionSubnetName
//    parent: vnetHub
//    properties: {
//      addressPrefix: bastionAddressPrefix
//    }
//    dependsOn:[
//      vnetHub
//     ]
// }
// resource devOpsSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
//   name: devOpsSubnetName
//    parent: vnetHub
//    properties: {
//      addressPrefix: devOpsNameAddressPrefix
//    }
//    dependsOn:[
//     vnetHub
//     bastionSubnet
//    ]
// }
// resource jumpBoxSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
//   name: jumpBoxSubnetName
//    parent: vnetHub
//    properties: {
//      addressPrefix: jumpBoxAddressPrefix
//    }
//    dependsOn:[
//     vnetHub
//     bastionSubnet
//     devOpsSubnet
//    ]
// }

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: spokeVNetName
  location: resourceGroup().location
  tags: {
    Owner: owner
    // CostCenter: costCenter
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVNetNameAddressPrefix
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: [
      {
        name: aseSubnetName
        properties: {
          addressPrefix: aseAddressPrefix
        }
      }
    ]
  }
}

// resource aseSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
//   name: aseSubnetName
//    parent: vnetSpoke
//    properties: {
//      addressPrefix: aseAddressPrefix
//    }
//    dependsOn:[
//     vnetSpoke
//    ]
// }

// Peering
resource vnetHubPeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${vnetHub.name}/${vnetHub.name}-${vnetSpoke.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetSpoke.id
    }
  }
  dependsOn:[
    vnetHub
    vnetSpoke
   ]
}

resource vnetSpokePeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${vnetSpoke.name}/${vnetSpoke.name}-${vnetHub.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
  }
  dependsOn:[
    vnetHub
    vnetSpoke
   ]
}


// Output section
output hubVNet object = vnetHub
output spokeVNet object = vnetSpoke
