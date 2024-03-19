# Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep
$rg = 'aks'
$loc = 'eastus'
$cluster = 'aksustest'

New-AzResourceGroup -Name $rg -Location $loc `
   -Tag @{topic="4"; question="20"} `
   -Confirm

New-AzAksCluster -Location $loc `
  -ResourceGroupName $rg `
  -Name $cluster `
  -NodeCount 1 `
  -EnableManagedIdentity `
  -NodePoolMode System `
  -NodeVmSetType VirtualMachineScaleSets `
  -NodeVmSize Standard_B2als_v2 `
  -NodeOsSKU Ubuntu

# Expose ClusterIP services to the Internet via Application Http App rounting
az aks approuting enable -g $rg -n $cluster

# Configure cluster autoscaler
Set-AzAksCluster -EnableNodeAutoScaling -Name $cluster `
 -ResourceGroupName $rg `
 -NodeMinCount 1 `
 -NodeMaxCount 2 `
 -AutoScalerProfile @{ScaleDownUnneededTime="1m";ScaleDownDelayAfterAdd="2m"}

 az aks update --enable-cluster-autoscaler `
   --name $cluster `
   --resource-group $rg `
   --min-count 1 `
   --max-count 2 `
   --cluster-autoscaler-profile scale-down-unneeded-time=1m scale-down-delay-after-add=2m

 