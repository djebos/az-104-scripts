Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9

Select-AzSubscription -SubscriptionName firstsub

New-AzResourceGroup -Name disks -Location "eastus" `
   -Tag @{topic="3"; question="78"}

$cred = Get-Credential

New-AzVM -Name vm1 -Credential $cred -ResourceGroupName disks `
  -Image Win2016Datacenter -Size Standard_D2S_V3

# Must be enabled for encryption
New-AzKeyvault -name keyvault1disk -ResourceGroupName azureDiskEncryption -Location EastUS -EnabledForDiskEncryption

$keyVault= Get-AzKeyVault -VaultName keyvault1disk -ResourceGroupName disks

Set-AzVMDiskEncryptionExtension -ResourceGroupName disks -VMName vm1 -DiskEncryptionKeyVaultUrl $keyVault.VaultUri -DiskEncryptionKeyVaultId $keyVault.ResourceId

Get-AzVmDiskEncryptionStatus -VMName vm1 -ResourceGroupName disks
