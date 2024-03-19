Select-AzSubscription -SubscriptionName certification-prep
$rg = 'aks'
$loc = 'eastus'

Remove-AzResourceGroup -Name $rg -Force
Remove-AzResourceGroup -Name MC_aks_aksustest_eastus -Force