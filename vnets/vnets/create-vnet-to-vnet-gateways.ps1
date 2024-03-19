#Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep
$rg1 = 'vnets-peering-eus'
$rg2 = 'vnets-peering-cus'
$loc1 = 'eastus'
$loc2 = 'centralus'

New-AzResourceGroup -Name $rg1 -Location $loc1 `
    -Tag @{topic = "5"; question = "31" }


$vnetEus = (New-AzVirtualNetwork `
        -Name vnet-eus `
        -ResourceGroupName $rg1 `
        -Location $loc1 `
        -AddressPrefix "10.0.0.0/16")

Add-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix 10.0.255.0/27 -VirtualNetwork $vnetEus
$vnetEus | Set-AzVirtualNetwork

$vnetEus = Get-AzVirtualNetwork -Name vnet-eus -ResourceGroupName $rg1
$subnet = Get-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnetEus

$gwEusIp = New-AzPublicIpAddress -Name "eusGwIp" -ResourceGroupName $rg1 -Location $loc1 -AllocationMethod Static
$gwEusIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name gwEusIpConfig -SubnetId $subnet.Id -PublicIpAddressId $gwEusIp.Id

$vnetGwEus = (New-AzVirtualNetworkGateway `
    -Name eusGW `
    -ResourceGroupName $rg1 `
    -Location $loc1 `
    -IpConfigurations $gwEusIpConfig `
    -GatewayType "Vpn" `
    -VpnType "RouteBased" `
    -GatewaySku VpnGw1 `
    -VpnGatewayGeneration "Generation1")

Select-AzSubscription -SubscriptionName certification-prep2
New-AzResourceGroup -Name $rg2 -Location $loc2 `
    -Tag @{topic = "5"; question = "31" }

$vnetCus = (New-AzVirtualNetwork `
        -Name vnet-cus `
        -ResourceGroupName $rg2 `
        -Location $loc2 `
        -AddressPrefix "10.1.0.0/16")

Add-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix 10.1.255.0/27 -VirtualNetwork $vnetCus
$vnetCus | Set-AzVirtualNetwork
  
$vnetCus = Get-AzVirtualNetwork -Name vnet-cus -ResourceGroupName $rg2
$cusSubnet = Get-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnetCus
  
$gwCusIp = New-AzPublicIpAddress -Name "cusGwIp" -ResourceGroupName $rg2 -Location $loc2 -AllocationMethod Static
$gwCusIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name gwCusIpConfig -SubnetId $cusSubnet.Id -PublicIpAddressId $gwCusIp.Id
  
$vnetGwCus = (New-AzVirtualNetworkGateway `
    -Name cusGW `
    -ResourceGroupName $rg2 `
    -Location $loc2 `
    -IpConfigurations $gwCusIpConfig `
    -GatewayType "Vpn" `
    -VpnType "RouteBased" `
    -GatewaySku VpnGw1 `
    -VpnGatewayGeneration "Generation1")

# connecting eus to cus    
Select-AzSubscription -SubscriptionName certification-prep
New-AzVirtualNetworkGatewayConnection -Name "vNetEusTovNetCus" -ResourceGroupName $rg1 -VirtualNetworkGateway1 $vnetGwEus -VirtualNetworkGateway2 $vnetGwCus -Location $loc1 -ConnectionType Vnet2Vnet -SharedKey 'SuperSafekey3228'

# connecting cus to eus (bidirectional)    
Select-AzSubscription -SubscriptionName certification-prep2
New-AzVirtualNetworkGatewayConnection -Name "vNetCusTovNetEus" -ResourceGroupName $rg2 -VirtualNetworkGateway1 $vnetGwCus -VirtualNetworkGateway2 $vnetGwEus -Location $loc2 -ConnectionType Vnet2Vnet -SharedKey 'SuperSafekey3228'