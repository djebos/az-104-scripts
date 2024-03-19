Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep
$rg = 'vnets-nic-lb-nsg'
$loc = 'eastus'

New-AzResourceGroup -Name $rg -Location $loc `
   -Tag @{topic="Networks"; question="59"}

$VMLocalAdminUser = "azureuser"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "Azureuser450" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

New-AzVM -ResourceGroupName $rg `
 -Name vm1alerts `
 -Location $loc `
 -Image 'canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest' `
 -Size Standard_B1s `
 -OpenPorts 22 `
 -Credential $Credential `
 -OSDiskDeleteOption Delete `
 -AllocationMethod Static `
 -PublicIpAddressName pubIpVmAlerts

