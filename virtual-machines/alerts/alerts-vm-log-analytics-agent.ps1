# Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep
$rg = 'alerts'
$loc = 'eastus'

$VMLocalAdminUser = "azureuser"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "Studentwow322" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

# New-AzVM -ResourceGroupName $rg `
#  -Name vm1alerts `
#  -Location $loc `
#  -Image 'canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest' `
#  -Size Standard_B1s `
#  -OpenPorts 22 `
#  -Credential $Credential `
#  -OSDiskDeleteOption Delete `
#  -AllocationMethod Static `
#  -PublicIpAddressName pubIpVmAlerts

New-AzResourceGroup -Name $rg -Location $loc `
   -Tag @{topic = "Compute"; question = "65" } -Force

New-AzVm `
   -Credential $Credential `
   -ResourceGroupName $rg `
   -Name 'myVM' `
   -Location $loc `
   -Image 'Win2016Datacenter' `
   -VirtualNetworkName 'myVnet' `
   -SubnetName 'mySubnet' `
   -SecurityGroupName 'myNetworkSecurityGroup' `
   -PublicIpAddressName 'myPublicIpAddress' `
   -OpenPorts 3389

# Create Azure Analytics Worksapce   
$workspaceName = "mmaWorkspace"
New-AzOperationalInsightsWorkspace -Location $loc -Name $workspaceName -ResourceGroupName $rg
$workspaceId = (Get-AzOperationalInsightsWorkspace -Name $workspaceName -ResourceGroupName $rg).CustomerId
$workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $rg -Name $workspaceName).PrimarySharedKey
Write-Host "Workspace id $workspaceId"
Write-Host "Key: $workspaceKey"
$PublicSettings = @{"workspaceId" = $workspaceId}
 $ProtectedSettings = @{"workspaceKey" = $workspaceKey}
# Takes ages to install
Set-AzVMExtension -ExtensionName "MicrosoftMonitoringAgent" `
    -ResourceGroupName $rg `
    -VMName "myVM" `
    -Publisher "Microsoft.EnterpriseCloud.Monitoring" `
    -ExtensionType "MicrosoftMonitoringAgent" `
    -TypeHandlerVersion 1.0 `
    -Settings $PublicSettings `
    -ProtectedSettings $ProtectedSettings `
    -Location $loc

# clean up

Remove-AzResourceGroup -Name $rg
az monitor scheduled-query list -g $rg
az monitor metrics alert show -g $rg -n 'alertRule1'