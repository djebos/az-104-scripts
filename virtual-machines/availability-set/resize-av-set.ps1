Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep
$rg = 'av-set-resize3'
$loc = 'eastus'
$avSetName='AvailabilitySet01'

New-AzResourceGroup -Name $rg -Location $loc `
   -Tag @{topic="Miscalleneous"; question="16"}

$VMLocalAdminUser = "azureuser"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "Azureuser450" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
# Must be aligned to support managed disks
New-AzAvailabilitySet `
-ResourceGroupName $rg `
-Name $avSetName `
-Location $loc `
-Sku Aligned `
-PlatformFaultDomainCount 3 `
-PlatformUpdateDomainCount 1

$vnetEus = (New-AzVirtualNetwork `
        -Name vnet-eus `
        -ResourceGroupName $rg `
        -Location $loc `
        -AddressPrefix "10.0.0.0/16")

Add-AzVirtualNetworkSubnetConfig -Name 'subnet' -AddressPrefix 10.0.255.0/27 -VirtualNetwork $vnetEus
$vnetEus | Set-AzVirtualNetwork

New-AzVM -ResourceGroupName $rg `
 -Name vm1 `
 -Location $loc `
 -VirtualNetworkName vnet-eus `
 -SubnetName subnet `
 -Image 'canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest' `
 -Size Standard_B1s `
 -AvailabilitySetName $avSetName `
 -OpenPorts 22 `
 -Credential $Credential `
 -OSDiskDeleteOption Delete `
 -AllocationMethod Static `
 -PublicIpAddressName pubIpVm1


New-AzVM -ResourceGroupName $rg `
-Name vm2 `
-Location $loc `
-VirtualNetworkName vnet-eus `
-SubnetName subnet `
-Image 'canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest' `
-Size Standard_B1s `
-AvailabilitySetName $avSetName `
-OpenPorts 22 `
-Credential $Credential `
-OSDiskDeleteOption Delete `
-AllocationMethod Static `
-PublicIpAddressName pubIpVm2

# Must fail because resize operation is done for VM in availability set
# $ErrorActionPreference = "Continue"
# $vm = Get-AzVM -ResourceGroupName $rg -VMName vm1
# $vm.HardwareProfile.VmSize = 'Standard_B2as_v2'
# Update-AzVM -VM $vm -ResourceGroupName $rg

$newVmSize = "Standard_B2s_v2"

# Check if the desired VM size is available
$availableSizes = Get-AzVMSize -ResourceGroupName $rg -VMName vm1 |
  Select-Object -ExpandProperty Name
if ($availableSizes -notcontains $newVmSize) {
  # Deallocate all VMs in the availability set
  Write-Host "Deallocating all the VMs from Availability set bacause $newVmSize isn't supported"
  $as = Get-AzAvailabilitySet -ResourceGroupName $rg -Name $avSetName
  $virtualMachines = $as.VirtualMachinesReferences | Get-AzResource | Get-AzVM
  $virtualMachines | Stop-AzVM -Force -NoWait

# Resize and restart the VMs in the availability set
  $virtualMachines | Foreach-Object { $_.HardwareProfile.VmSize = $newVmSize }
  $virtualMachines | Update-AzVM
  $virtualMachines | Start-AzVM
  exit
}

# Resize the VM
Write-Host "Deallocation not needed, $newVmSize is supported"
$vm = Get-AzVM -ResourceGroupName $rg -VMName vm1
$vm.HardwareProfile.VmSize = $newVmSize
Update-AzVM -VM $vm -ResourceGroupName $rg