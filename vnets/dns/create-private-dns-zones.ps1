#Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep

$rg = 'private-dns-zones-auto-reg-2'
$loc = 'eastus'
New-AzResourceGroup -Name $rg -Location $loc `
   -Tag @{topic="Networking"; question="73"}

# private DNS zones, zones are location agnostic
New-AzPrivateDnsZone -Name Zone1.com -ResourceGroupName $rg 
New-AzPrivateDnsZone -Name Zone2.com -ResourceGroupName $rg 
New-AzPrivateDnsZone -Name Zone3.com -ResourceGroupName $rg

# vnets
$vnet1 = New-AzVirtualNetwork -Name vnet1 -Location westus -ResourceGroupName $rg -AddressPrefix "10.1.0.0/16"
$vnet2 = New-AzVirtualNetwork -Name vnet2 -Location westus -ResourceGroupName $rg -AddressPrefix "10.2.0.0/16"
$vnet3 = New-AzVirtualNetwork -Name vnet3 -Location eastus -ResourceGroupName $rg -AddressPrefix "10.3.0.0/16"

# link accordingly
New-AzPrivateDnsVirtualNetworkLink -ZoneName Zone1.com -ResourceGroupName $rg -Name link1 -VirtualNetworkId $vnet1.Id -EnableRegistration
New-AzPrivateDnsVirtualNetworkLink -ZoneName Zone2.com -ResourceGroupName $rg -Name link2 -VirtualNetworkId $vnet2.Id
New-AzPrivateDnsVirtualNetworkLink -ZoneName Zone3.com -ResourceGroupName $rg -Name link3 -VirtualNetworkId $vnet3.Id

# enable vm auto-registration for vnet2, must be OK!
Set-AzPrivateDnsVirtualNetworkLink -ZoneName Zone2.com -Name link2 -ResourceGroupName $rg -IsRegistrationEnabled $true

# try to link zone3 to vnet1, must be OK
New-AzPrivateDnsVirtualNetworkLink -ZoneName Zone3.com -ResourceGroupName $rg -Name link4 -VirtualNetworkId $vnet1.Id

# try to link zone1 to vnet2, fails because:
#A virtual network can only be linked to 1 Private DNS zone(s) with auto-registration enabled (vnet2 is auto-registered in zone2)
#But if we disable auto-registration in zone2 it must pass
$ErrorActionPreference = "Continue"
Set-AzPrivateDnsVirtualNetworkLink -ZoneName Zone2.com -Name link2 -ResourceGroupName $rg -IsRegistrationEnabled $false
New-AzPrivateDnsVirtualNetworkLink -ZoneName Zone1.com -ResourceGroupName $rg -Name link5 -VirtualNetworkId $vnet2.Id -EnableRegistration

# enable vm auto-registration for vnet1 in zone3, fails because vnet1 has auto-registration enabled in zone1
Set-AzPrivateDnsVirtualNetworkLink -ZoneName Zone3.com -Name link4 -ResourceGroupName $rg -IsRegistrationEnabled $true


