#Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

# Select-AzSubscription -SubscriptionName certification-prep
$rg = 'arm-manager-temp-deploy'
$loc = 'eastus'
New-AzResourceGroup -Name $rg -Location $loc `
   -Tag @{topic = "Compute"; question = "45" } -Force

$user = "azureuser";
$securePassword = "Azureuser450" | ConvertTo-SecureString -AsPlainText -Force;  
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);

New-AzVm `
   -Credential $cred `
   -ResourceGroupName $rg `
   -Name 'myVM' `
   -Location $loc `
   -Image 'Win2019Datacenter' `
   -VirtualNetworkName 'myVnet' `
   -SubnetName 'mySubnet' `
   -SecurityGroupName 'myNetworkSecurityGroup' `
   -PublicIpAddressName 'myPublicIpAddress' `
   -OpenPorts 3389