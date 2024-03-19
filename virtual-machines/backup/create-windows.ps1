#Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep
# $rg = 'backup-vms'
$rg = 'restore-vms'
$loc = 'eastus'
New-AzResourceGroup -Name $rg -Location $loc `
   -Tag @{topic = "Compute"; question = "55" } -Force

$user = "azureuser";
$securePassword = "Azureuser450" | ConvertTo-SecureString -AsPlainText -Force;  
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);

New-AzVm `
   -Credential $cred `
   -ResourceGroupName $rg `
   -Name 'vm1' `
   -Location $loc `
   -Image 'Win2016Datacenter' `
   -VirtualNetworkName 'myVnet' `
   -SubnetName 'mySubnet' `
   -SecurityGroupName 'myNetworkSecurityGroup1' `
   -PublicIpAddressName 'myPublicIpAddress1' `
   -Size Standard_B2as_v2 `
   -OpenPorts 3389


New-AzVm `
   -Credential $cred `
   -ResourceGroupName $rg `
   -Name 'vm2' `
   -Location $loc `
   -Image 'Win2016Datacenter' `
   -VirtualNetworkName 'myVnet' `
   -SubnetName 'mySubnet' `
   -SecurityGroupName 'myNetworkSecurityGroup2' `
   -PublicIpAddressName 'myPublicIpAddress2' `
   -Size Standard_B2as_v2 `
   -OpenPorts 3389

   

New-AzRecoveryServicesVault `
   -Name restoreMarsVault `
   -ResourceGroupName $rg `
   -Location $loc