#Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep
$rg = 'firewall-vnet'
$rg2 = 'firewall-another-rg'
$loc = 'eastus'
$locWus = 'westus'

# Remove-AzResourceGroup -Name $rg -Force

New-AzResourceGroup `
    -Name $rg `
    -Location $loc `
    -Tag @{topic = "Networking"; question = "110" }

# /26 prefix is minimum, /27 prefix is minimum for VPN gateway
$FWsub = New-AzVirtualNetworkSubnetConfig `
    -Name AzureFirewallSubnet `
    -AddressPrefix 10.0.1.0/26
$vnetFW = New-AzVirtualNetwork `
    -Name vnetFW `
    -ResourceGroupName $rg `
    -Location $loc `
    -AddressPrefix 10.0.0.0/16 `
    -Subnet $FWsub

## Create public IP (Standard static ipv4 supported only) ##
$ip = @{
    Name              = 'standardPublicIP'
    ResourceGroupName = $rg
    Location          = $loc
    Sku               = 'Standard'
    AllocationMethod  = 'Static'
    IpAddressVersion  = 'IPv4'
}
$standardPublicIP = (New-AzPublicIpAddress @ip)

$Azfw = New-AzFirewall -Name firewallSameRg -ResourceGroupName $rg `
    -Location $loc `
    -VirtualNetwork $vnetFW `
    -PublicIpAddress $standardPublicIP

# Azure Firewall cannot be created in a resource group that is different from the one used by the protected vnet
New-AzResourceGroup `
    -Name $rg2 `
    -Location $loc `
    -Tag @{topic = "Networking"; question = "110" }
# /26 prefix is minimum
$FWsub2 = New-AzVirtualNetworkSubnetConfig `
    -Name AzureFirewallSubnet `
    -AddressPrefix 10.0.1.0/26
$vnetFW2 = New-AzVirtualNetwork `
    -Name vnetFW2 `
    -ResourceGroupName $rg `
    -Location $loc `
    -AddressPrefix 10.0.0.0/16 `
    -Subnet $FWsub2


## Create public IP (Standard static ipv4 supported only) (can be in a different resource-group) ##
$ip = @{
    Name              = 'standardPublicIP2'
    ResourceGroupName = $rg2
    Location          = $loc
    Sku               = 'Standard'
    AllocationMethod  = 'Static'
    IpAddressVersion  = 'IPv4'
}
$standardPublicIP2 = (New-AzPublicIpAddress @ip)
$ErrorActionPreference = "Continue"
$Azfw2 = New-AzFirewall -Name firewallAnotherRg -ResourceGroupName $rg2 `
    -Location $loc `
    -VirtualNetwork $vnetFW2 `
    -PublicIpAddress $standardPublicIP2

# Public ip isn't in firewall's region so it fails
## Create public IP (Standard static ipv4 supported only) (cannot be in a different region) ##
$ip = @{
    Name              = 'standardPublicIPWest'
    ResourceGroupName = $rg
    Location          = $locWus
    Sku               = 'Standard'
    AllocationMethod  = 'Static'
    IpAddressVersion  = 'IPv4'
}
$standardPublicIP3 = (New-AzPublicIpAddress @ip)
$Azfw3 = New-AzFirewall -Name firewallAnotherRg -ResourceGroupName $rg `
    -Location $loc `
    -VirtualNetwork $vnetFW2 `
    -PublicIpAddress $standardPublicIP3