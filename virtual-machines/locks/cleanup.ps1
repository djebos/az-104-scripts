#Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Continue"

Select-AzSubscription -SubscriptionName certification-prep
$loc = 'eastus'

#remove groups
foreach ($group in (Get-AzResourceGroup -Name rg-locks-*)) {
   Get-AzResourceLock -ResourceGroupName $group.ResourceGroupName | Remove-AzResourceLock -Force
   Remove-AzResourceGroup -Name $group.ResourceGroupName -Force
}
