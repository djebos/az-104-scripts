#Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep
$rg = 'firewall5'
$loc = 'eastus2'
$loc2 = 'westus'

# Remove-AzResourceGroup -Name $rg -Force

New-AzResourceGroup -Name $rg -Location $loc `
   -Tag @{topic = "Compute"; question = "90" }

# can be deployed only to home regions, thus if participating region fails the traffic won't be affected 
# https://learn.microsoft.com/uk-ua/azure/load-balancer/cross-region-overview#home-regions-in-azure
# Works with firewall if in the same location
$ip = @{
    Name = 'standardPublicIP-Global'
    ResourceGroupName = $rg
    Location = 'eastus2'
    Sku = 'Standard'
    AllocationMethod = 'Static'
    IpAddressVersion = 'IPv4'
    Tier = 'Global'
}
$standardPublicIPGlobal = New-AzPublicIpAddress @ip

## Create IP tag for Internet and Routing Preference. ##
$tag = @{
   IpTagType = 'RoutingPreference'
   Tag = 'Internet'   
}
$ipTag = New-AzPublicIpTag @tag

## Create IP. ##
$ip = @{
   Name = 'zonalStandardPublicIP-InternetRoute'
   ResourceGroupName = $rg
   Location = $loc
   Sku = 'Standard'
   AllocationMethod = 'Static'
   IpAddressVersion = 'IPv4'
   IpTag = $ipTag
   Zone = 1,2,3   
}
$zonalStandardPublicIpInternetRoute = (New-AzPublicIpAddress @ip)
# Azure Firewall doesn't currently support IPv6. It can operate in a dual stack virtual network using only IPv4, but the firewall subnet must be IPv4-only.
## Create IP. ##
$ip = @{
   Name = 'standardPublicIP-IPv6'
   ResourceGroupName = $rg
   Location = $loc
   Sku = 'Standard'
   AllocationMethod = 'Static'
   IpAddressVersion = 'IPv6'
}
$standardPublicIPv6 = (New-AzPublicIpAddress @ip)

# Doesn't work: AzureFirewall firewall1 references a non standard Public IP
$ip = @{
   Name = 'basicPublicIP'
   ResourceGroupName = $rg
   Location = $loc2
   Sku = 'Basic'
   AllocationMethod = 'Static'
   IpAddressVersion = 'IPv4'
}
$basicPublicIp = (New-AzPublicIpAddress @ip)

$ip = @{
   Name = 'basicPublicIPDynamic'
   ResourceGroupName = $rg
   Location = $loc2
   Sku = 'Basic'
   AllocationMethod = 'Dynamic'
   IpAddressVersion = 'IPv4'
}
$basicPublicIPDynamic = (New-AzPublicIpAddress @ip)

$Bastionsub = New-AzVirtualNetworkSubnetConfig -Name AzureBastionSubnet -AddressPrefix 10.0.0.0/27
$FWsub = New-AzVirtualNetworkSubnetConfig -Name AzureFirewallSubnet -AddressPrefix 10.0.1.0/26
$Worksub = New-AzVirtualNetworkSubnetConfig -Name Workload-SN -AddressPrefix 10.0.2.0/24
# same region as firewall
$testVnet = New-AzVirtualNetwork -Name Test-FW-VN -ResourceGroupName $rg `
-Location $loc -AddressPrefix 10.0.0.0/16 -Subnet $Bastionsub, $FWsub, $Worksub

# Firewall, vnet and public IP must be in the same region
$Azfw = New-AzFirewall -Name firewall1 -ResourceGroupName $rg `
  -Location $loc `
  -VirtualNetwork $testVnet `
  -PublicIpAddress $standardPublicIPv6

$rgVnet = 'firewall-vnet'

New-AzResourceGroup -Name $rg -Location $loc `
-Tag @{topic = "Networking"; question = "110" }