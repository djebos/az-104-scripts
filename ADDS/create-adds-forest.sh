#!/usr/bin/env bash

#Update based on your organizational requirements
Location=eastus
ResourceGroupName=ADonAzureVMs
NetworkSecurityGroup=NSG-DomainControllers
VNetName=VNet-AzureVMsEastUs
VNetAddress=10.10.0.0/16
SubnetName=Subnet-AzureDCsEastUs2
SubnetAddress=10.10.10.0/24
AvailabilitySet=DomainControllers
VMSize=Standard_DS1_v2
DataDiskSize=20
AdminUsername=azureuser
AdminPassword=ChangeMe123456
DomainController1=AZDC01
DC1IP=10.10.10.11
DomainController2=AZDC02
DC2IP=10.10.10.12

# az login --tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
# # Create a resource group.
# az group create --name $ResourceGroupName --location $Location

# # Create a network security group
# az network nsg create --name $NetworkSecurityGroup --resource-group $ResourceGroupName --location $Location

# # Create a network security group rule for port 3389.
# az network nsg rule create --name PermitRDP --nsg-name $NetworkSecurityGroup --priority 1000 --resource-group $ResourceGroupName --access Allow --source-address-prefixes "*" --source-port-ranges "*" --direction Inbound --destination-port-ranges 3389

# # Create a virtual network.
# az network vnet create --name $VNetName --resource-group $ResourceGroupName --address-prefixes $VNetAddress --location $Location 

# # Create a subnet
# az network vnet subnet create --address-prefix $SubnetAddress --name $SubnetName --resource-group $ResourceGroupName --vnet-name $VNetName --network-security-group $NetworkSecurityGroup

# # Create an availability set.
# az vm availability-set create --name $AvailabilitySet --resource-group $ResourceGroupName --location $Location

# Create two virtual machines.
az vm create --resource-group $ResourceGroupName --availability-set $AvailabilitySet --name $DomainController1 --size $VMSize --image Win2019Datacenter --admin-username $AdminUsername --admin-password $AdminPassword --data-disk-sizes-gb $DataDiskSize --data-disk-caching None --nsg $NetworkSecurityGroup --private-ip-address $DC1IP --no-wait

# az vm create --resource-group $ResourceGroupName --availability-set $AvailabilitySet --name $DomainController2 --size $VMSize --image Win2019Datacenter --admin-username $AdminUsername --admin-password $AdminPassword --data-disk-sizes-gb $DataDiskSize --data-disk-caching None --nsg $NetworkSecurityGroup --private-ip-address $DC2IP