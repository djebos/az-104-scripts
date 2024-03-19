#https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-automatic-upgrade 
# not more than 20% of VMs are updated simultenioiusly, min 1. OS disk is replaced, data disks retained, extendions and scripts executed again
Update-AzVmss -ResourceGroupName "myResourceGroup" -VMScaleSetName "myScaleSet" -AutomaticOSUpgrade $true