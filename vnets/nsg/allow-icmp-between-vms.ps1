Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep
$rg = 'vnets-nsg-icmp'
$loc = 'eastus'

New-AzResourceGroup -Name $rg -Location $loc `
   -Tag @{topic="Networks"; question="85"}

$VMLocalAdminUser = "azureuser"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "Azureuser450" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

$vmname = 'vm1';
$vmname2 = 'vm2';
$vnetname = "vnet1-deny-ping";
$vnetAddress = "10.0.0.0/16";
$subnetname = "slb" + $rg;
$subnetAddress = "10.0.2.0/24";
$NICName = $vmname+ "-nic";
$NSGName = "NSG-deny-ping";
$VMSize = "Standard_B1ms";
$PublisherName = "canonical";
$Offer = "0001-com-ubuntu-server-focal";
$SKU = "20_04-lts-gen2";
$version = "latest";

# Network setup
$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetname -AddressPrefix $subnetAddress;
$vnet = New-AzVirtualNetwork -Name $vnetname -ResourceGroupName $rg -Location $loc -AddressPrefix $vnetAddress -Subnet $subnet;
$nsgRuleHTTPS = New-AzNetworkSecurityRuleConfig -Name ALLOW_HTTPS  -Protocol Tcp  -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443 -Access Allow;
$nsgRuleDenyICMP = New-AzNetworkSecurityRuleConfig -Name DENY_PING  -Protocol ICMP  -Direction Outbound -Priority 111 -SourceAddressPrefix VirtualNetwork -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange * -Access Deny;
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $rg -Location $loc -Name $NSGName  -SecurityRules $nsgRuleHTTPS, $nsgRuleDenyICMP;

$vnet.Subnets[0].NetworkSecurityGroup = $nsg
Set-AzVirtualNetwork -VirtualNetwork $vnet

$nic = New-AzNetworkInterface -Name $NICName -ResourceGroupName $rg -Location $loc -SubnetId $vnet.Subnets[0].Id;
$nic.IpConfigurations[0].PrivateIpAddress
# VM 1
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $VMSize;
Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName $vmName -Credential $Credential;
Set-AzVMSourceImage -VM $vmConfig -PublisherName $PublisherName -Offer $Offer -Skus $SKU -Version $version ;
Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id;

$vm1 = New-AzVM -ResourceGroupName $rg -Location $loc -VM $vmConfig;

# VM 2
$nic2 = New-AzNetworkInterface -Name 'vm2-nic' -ResourceGroupName $rg -Location $loc -SubnetId $vnet.Subnets[0].Id;
$nic2.IpConfigurations[0].PrivateIpAddress
$vmConfig2 = New-AzVMConfig -VMName $vmName2 -VMSize $VMSize;
Set-AzVMOperatingSystem -VM $vmConfig2 -Linux -ComputerName $vmName2 -Credential $Credential;
Set-AzVMSourceImage -VM $vmConfig2 -PublisherName $PublisherName -Offer $Offer -Skus $SKU -Version $version ;
Add-AzVMNetworkInterface -VM $vmConfig2 -Id $nic2.Id;

$vm2 = New-AzVM -ResourceGroupName $rg -Location $loc -VM $vmConfig2;

# Fix outbound communication from vm1 to vm2, vice versa won't work because we stick to IP rule but not VirtualNetwork one
Get-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $rg `
  | Add-AzNetworkSecurityRuleConfig -Name "Ping-Rule" `
    -Description "Allow Ping" `
    -Access "Allow" `
    -Protocol "ICMP" `
    -Direction "Outbound" `
    -Priority 110 `
    -SourceAddressPrefix (Get-AzNetworkInterface -Name $nic.Name -ResourceGroupName $rg).IpConfigurations[0].PrivateIpAddress `
    -SourcePortRange "*" `
    -DestinationAddressPrefix (Get-AzNetworkInterface -Name $nic2.Name -ResourceGroupName $rg).IpConfigurations[0].PrivateIpAddress `
    -DestinationPortRange "*" `
  | Set-AzNetworkSecurityGroup
