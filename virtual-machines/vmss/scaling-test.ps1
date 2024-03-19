#Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep
$subscriptionId = 'e7dc935a-7e69-4b70-90e9-4a4eb71d7ca6'
$rg = 'vmss-scaling14'
$loc = 'eastus'
$vmssName = 'scalingVmss'
New-AzResourceGroup -Name $rg -Location $loc `
   -Tag @{topic = "Compute"; question = "98" } -Force

$user = "azureuser";
$securePassword = "Azureuser450" | ConvertTo-SecureString -AsPlainText -Force;  
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);

# $nsgRuleSSh = New-AzNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow SSH" `
# -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
# Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22

# $nsg = New-AzNetworkSecurityGroup `
#    -Name nsgSSH `
#    -ResourceGroupName $rg `
#    -Location $loc `
#    -SecurityRules $nsgRuleSSh

$bytes = [System.IO.File]::ReadAllBytes("cloud-init.yml");
$userData = [Convert]::ToBase64String($bytes);
$vmssId = (New-AzVmss `
   -ResourceGroupName "$rg" `
   -Location $loc `
   -VMScaleSetName $vmssName `
   -VirtualNetworkName "myVnet" `
   -SubnetName "mySubnet" `
   -PublicIpAddressName "myPublicIPAddress" `
   -OrchestrationMode 'Uniform' `
   -LoadBalancerName 'myLoadBalancer' `
   -InstanceCount 1 `
   -VmSize Standard_B1ms `
   -ImageName Ubuntu2204 `
   -Credential $cred `
   -UserData $userData).id
# commenting due to conflict with custom nat because scale set creates NAT entries on its own
# # Get the existing vNet and subnet configuration
# $vnet = Get-AzVirtualNetwork -ResourceGroupName $rg -Name 'myVnet'
# $subnet = $vnet.Subnets | Where-Object { $_.Name -eq 'mySubnet' }

# $subnet.NetworkSecurityGroup = $nsg

# Set-AzVirtualNetwork -VirtualNetwork $vnet

$protocol = "Tcp"
$frontendPort = 5000   # The external port you want to use for SSH
$backendPort = 22     # The internal port on the VMs

# Get the existing Load Balancer
$loadBalancer = Get-AzLoadBalancer -ResourceGroupName $rg -Name 'myLoadBalancer'

# Add a new SSH Inbound NAT rule
Add-AzLoadBalancerInboundNatRuleConfig `
    -LoadBalancer $loadBalancer `
    -Name "ssh-rule" `
    -FrontendIpConfigurationId $loadBalancer.FrontendIpConfigurations[0].Id `
    -Protocol $protocol `
    -FrontendPortRangeStart $frontendPort `
    -FrontendPortRangeEnd ($frontendPort + 1000) `
    -BackendPort $backendPort `
    -BackendAddressPoolId $loadBalancer.BackendAddressPools[0].Id

$loadBalancer | Set-AzLoadBalancer

$rule1 = New-AzAutoscaleScaleRuleObject `
   -MetricTriggerMetricName "Percentage CPU" `
   -MetricTriggerMetricResourceUri "/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Compute/virtualMachineScaleSets/$vmssName"  `
   -MetricTriggerTimeGrain ([System.TimeSpan]::New(0, 1, 0)) `
   -MetricTriggerStatistic "Average" `
   -MetricTriggerTimeWindow ([System.TimeSpan]::New(0, 3, 0)) `
   -MetricTriggerTimeAggregation "Average" `
   -MetricTriggerOperator "GreaterThan" `
   -MetricTriggerThreshold 70 `
   -MetricTriggerDividePerInstance $false `
   -ScaleActionDirection "Increase" `
   -ScaleActionType "ChangeCount" `
   -ScaleActionValue 1 `
   -ScaleActionCooldown ([System.TimeSpan]::New(0, 5, 0))


$rule2 = New-AzAutoscaleScaleRuleObject `
   -MetricTriggerMetricName "Percentage CPU" `
   -MetricTriggerMetricResourceUri "/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Compute/virtualMachineScaleSets/$vmssName"  `
   -MetricTriggerTimeGrain ([System.TimeSpan]::New(0, 1, 0)) `
   -MetricTriggerStatistic "Average" `
   -MetricTriggerTimeWindow ([System.TimeSpan]::New(0, 3, 0)) `
   -MetricTriggerTimeAggregation "Average" `
   -MetricTriggerOperator "LessThan" `
   -MetricTriggerThreshold 30 `
   -MetricTriggerDividePerInstance $false `
   -ScaleActionDirection "Decrease" `
   -ScaleActionType "ChangeCount" `
   -ScaleActionValue 1 `
   -ScaleActionCooldown ([System.TimeSpan]::New(0, 5, 0))

$defaultProfile = New-AzAutoscaleProfileObject `
   -Name "default" `
   -CapacityDefault 1 `
   -CapacityMaximum 4 `
   -CapacityMinimum 1 `
   -Rule $rule1, $rule2

New-AzAutoscaleSetting `
   -Name vmss-autoscalesetting2 `
   -ResourceGroupName $rg `
   -Location $loc `
   -Profile $defaultProfile `
   -Enabled `
   -PropertiesName "vmss-autoscalesetting2" `
   -TargetResourceUri (Get-AzVmss -ResourceGroupName $rg -VMScaleSetName $vmssName).Id

# Load around 80% for 15 minutes per instance, 30% scale in, 70% scale out
# First scale out happens after 3 minutes                                                               | 3m
# Second one happens in 5 minutes (cooldown > metric window)                                            | 8m
# Third one happens in 5 minutes (cooldown > metric window)                                             | 13m
# Forth happens in 5 minutes (cooldown) --> instance-0 load off, avg load (80*3 + 5)/4 = 65%            | 18m
# Four instances exist for another 5 minutues --> instance-1 load off, avg load (80*2 + 5 + 5)/4 = 42%  | 23m
# Four instances exist for another 5 minutes --> instance-2 load off, avg load (80 + 5 + 5 + 5)/4 = 24% | 28m
# Scale in initiated, instance cound 3                                                                  | 28m
# In 5 minutes instance-3 load off, avg load 5 + 5 + 5 /3 = 5                                           | 33m
# Scale in initiated, instance count 2                                                                  | 33m
# Wait 5 minutes, avg load 5 + 5 /2 = 5                                                                 | 38m
# Scale in initiated, instance count 1, minimum reached                                                 | 38m
