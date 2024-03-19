#Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep
$rg1 = 'rg-locks-111111'
$loc = 'eastus'
$rg2 = 'rg-locks-222222'
$rg3 = 'rg-locks-333333'

$vnetName = 'lockedVnet'
$vnetName2 = 'lockedVnet2'
$storageAccountName = 'storagelocked32288811'
$storageAccountName2 = 'storagelocked322888822'
$publicIpName = 'publicIpMove'

New-AzResourceGroup -Name $rg1 -Location $loc `
   -Tag @{topic="Networks"; question="51"}

New-AzResourceGroup -Name $rg2 -Location $loc `
   -Tag @{topic="Networks"; question="51"}

New-AzResourceLock -LockName lockRg2 -ResourceGroupName $rg2 -LockLevel CanNotDelete -Force

$storageAccount = New-AzStorageAccount -ResourceGroupName $rg1 -Location $loc -Name $storageAccountName  -SkuName Standard_LRS
New-AzResourceLock -LockName storageAccountLock -LockLevel ReadOnly -Scope $storageAccount.Id -Force

$publicIp = New-AzPublicIpAddress -Name $publicIpName -Location $loc -ResourceGroupName $rg1 -Sku Basic -AllocationMethod Dynamic 

$vnet = New-AzVirtualNetwork -Name $vnetName -Location $loc -ResourceGroupName $rg1 -AddressPrefix "10.1.0.0/16"
New-AzResourceLock -LockName vnetLock -LockLevel ReadOnly -Scope $vnet.Id -Force

#Moving locked resources is OK even if target resource group is locked on Delete level
# Takes much time
# Move-AzResource -DestinationResourceGroupName $rg2 -ResourceId $vnet.Id -Force
Move-AzResource -DestinationResourceGroupName $rg2 -ResourceId $storageAccount.Id -Force
# Move-AzResource -DestinationResourceGroupName $rg2 -ResourceId $publicIp.Id -Force

#Moving back locked resources is OK even if source resource goup is locked on Delete level
#Account for resource Id changes
# $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rg2
$storageAccount = Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $rg2
# $publicIp = Get-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $rg2

#Takes much time
# Move-AzResource -DestinationResourceGroupName $rg1 -ResourceId $vnet.Id -Force
# Move-AzResource -DestinationResourceGroupName $rg1 -ResourceId $storageAccount.Id -Force
# Move-AzResource -DestinationResourceGroupName $rg1 -ResourceId $publicIp.Id -Force

#Testing moving with ReadOnly resource group
New-AzResourceGroup -Name $rg3 -Location $loc `
   -Tag @{topic="Networks"; question="51"}

$storageAccount2 = New-AzStorageAccount -ResourceGroupName $rg3 -Location $loc -Name $storageAccountName2 -SkuName Standard_LRS
$vnet2 = New-AzVirtualNetwork -Name $vnetName2 -Location $loc -ResourceGroupName $rg3 -AddressPrefix "10.1.0.0/16"
New-AzResourceLock -LockName vnetLock2 -LockLevel ReadOnly -Scope $vnet.Id -Force
New-AzResourceLock -LockName storageLock2 -LockLevel CanNotDelete -Scope $storageAccount2.Id -Force
New-AzResourceLock -LockName lockRg3 -ResourceGroupName $rg3 -LockLevel ReadOnly -Force

# expected errors
$ErrorActionPreference = "Continue"
# Scope of rg3 is locked (ReadOnly) cannot move resources
Move-AzResource -DestinationResourceGroupName $rg1 -ResourceId $vnet2.Id -Force
Move-AzResource -DestinationResourceGroupName $rg1 -ResourceId $storageAccount2.Id -Force

#remove groups
Get-AzResourceLock -ResourceGroupName $rg1 | Remove-AzResourceLock -Force
Remove-AzResourceGroup -Name $rg1 -Force

Get-AzResourceLock -ResourceGroupName $rg2 | Remove-AzResourceLock -Force
Remove-AzResourceGroup -Name $rg2 -Force

Get-AzResourceLock -ResourceGroupName $rg3 | Remove-AzResourceLock -Force
Remove-AzResourceGroup -Name $rg3 -Force