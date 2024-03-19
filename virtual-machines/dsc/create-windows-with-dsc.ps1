#Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

# Select-AzSubscription -SubscriptionName certification-prep
$rg = 'dsc'
$loc = 'eastus'
New-AzResourceGroup -Name $rg -Location $loc `
   -Tag @{topic="4"; question="4"}


$image = (Get-AzVMImage -Location eastus -Publisher MicrosoftWindowsServer -Offer WindowsServer -Sku 2016-datacenter | Sort-Object -Property Version).id[0]

# $diskconfig = New-AzDiskConfig -Location $loc -SkuName Standard_LRS -OsType Windows -CreateOption 'FromImage'
# $diskconfig = Set-AzDiskImageReference -Disk $diskconfig -Id $image
# $osDisk = New-AzDisk -ResourceGroupName $rg -DiskName 'disk01' -Disk $diskconfig

$vmconfig = New-AzVMConfig -VMName vm1 -vmsize Standard_B2ms -SecurityType Standard;
$vmconfig = Set-AzVmSourceImage -VM $vmconfig -PublisherName MicrosoftWindowsServer -Skus 2016-datacenter -Offer WindowsServer -Version latest
# Credential. Input Username and Password values
$user = "azureuser";
$securePassword = "Azureuser450" | ConvertTo-SecureString -AsPlainText -Force;  
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);

$vmconfig = Set-AzVMOperatingSystem -VM $vmconfig -Credential $cred -ComputerName vm1
$vmconfig = Set-AzVMBootDiagnostic -VM $vmconfig -Disable
# $vmconfig = Set-AzVMOSDisk -VM $vmconfig -Name osDisk1 -CreateOption FromImage -SourceImageUri $image
#Vnet Config 


$defaultSubnet = New-AzVirtualNetworkSubnetConfig -Name default -AddressPrefix "10.0.1.0/24"
$vnet = New-AzVirtualNetwork -Force -Name vnet1 -ResourceGroupName $rg -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $defaultSubnet
$vnet = Get-AzVirtualNetwork -Name vnet1 -ResourceGroupName $rg;
$subnetId = $vnet.Subnets[0].Id;

$nsgRuleRdp = New-AzNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389

$nsg = New-AzNetworkSecurityGroup `
   -Name nsgRdp `
   -ResourceGroupName $rg `
   -Location $loc `
   -SecurityRules $nsgRuleRdp

$pubip = New-AzPublicIpAddress -Force -Name pubip1  -ResourceGroupName $rg -Location $loc -AllocationMethod Static;
$pubip = Get-AzPublicIpAddress -Name pubip1 -ResourceGroupName $rg;
$pubipId = $pubip.Id;
$nic = New-AzNetworkInterface -Force -Name vm1Nic -ResourceGroupName $rg -Location $loc -SubnetId $subnetId -PublicIpAddressId $pubip.Id -NetworkSecurityGroupId $nsg.Id;
$nic = Get-AzNetworkInterface -Name vm1Nic -ResourceGroupName $rg;
$nicId = $nic.Id;

$vmconfig = Add-AzVMNetworkInterface -VM $vmconfig -Id $nicId;

New-AzVM -ResourceGroupName $rg -Location eastus -Vm $vmConfig



$vm1 = Get-AzVM -ResourceGroupName $rg -Name vm1
# Remove-AzVM -Id $vm1.Id
# Remove-AzNetworkInterface -Force -Name vm1Nic -ResourceGroupName $rg
# Get-AzDisk -ResourceGroupName $rg | Remove-AzDisk
# Remove-AzPublicIpAddress -ResourceGroupName $rg -Name pubip1
