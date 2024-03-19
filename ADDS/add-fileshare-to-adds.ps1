# Change the execution policy to unblock importing AzFilesHybrid.psm1 module
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

# Navigate to where AzFilesHybrid is unzipped and stored and run to copy the files into your path
\Users\oleksiiboiarskyi\Desktop/az-104-materials\AzFilesHybrid\CopyToPSPath.ps1 

# Import AzFilesHybrid module
Import-Module -Name AzFilesHybrid

# Login to Azure using a credential that has either storage account owner or contributor Azure role 
# assignment. If you are logging into an Azure environment other than Public (ex. AzureUSGovernment) 
# you will need to specify that.
# See https://learn.microsoft.com/azure/azure-government/documentation-government-get-started-connect-with-ps
# for more information.
Connect-AzAccount

# Define parameters
# $StorageAccountName is the name of an existing storage account that you want to join to AD
# $SamAccountName is the name of the to-be-created AD object, which is used by AD as the logon name 
# for the object. It must be 20 characters or less and has certain character restrictions.
# Make sure that you provide the SamAccountName without the trailing '$' sign.
# See https://learn.microsoft.com/windows/win32/adschema/a-samaccountname for more information.
$SubscriptionId = "e7dc935a-7e69-4b70-90e9-4a4eb71d7ca6"
$ResourceGroupName = "ADonAzureVMs"
$StorageAccountName = "testfileshareadds"
$SamAccountName = "fileshareadds"
$DomainAccountType = "ComputerAccount" # Default is set as ComputerAccount
# If you don't provide the OU name as an input parameter, the AD identity that represents the 
# storage account is created under the root directory.
$OuDistinguishedName = ""
# Encryption method is AES-256 Kerberos.

# Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $SubscriptionId 

# Register the target storage account with your active directory environment under the target OU 
# (for example: specify the OU with Name as "UserAccounts" or DistinguishedName as 
# "OU=UserAccounts,DC=CONTOSO,DC=COM"). You can use this PowerShell cmdlet: Get-ADOrganizationalUnit 
# to find the Name and DistinguishedName of your target OU. If you are using the OU Name, specify it 
# with -OrganizationalUnitName as shown below. If you are using the OU DistinguishedName, you can set it 
# with -OrganizationalUnitDistinguishedName. You can choose to provide one of the two names to specify 
# the target OU. You can choose to create the identity that represents the storage account as either a 
# Service Logon Account or Computer Account (default parameter value), depending on your AD permissions 
# and preference. Run Get-Help Join-AzStorageAccountForAuth for more details on this cmdlet.

Join-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -SamAccountName $SamAccountName `
        -DomainAccountType $DomainAccountType `
        -OrganizationalUnitDistinguishedName $OuDistinguishedName

# You can run the Debug-AzStorageAccountAuth cmdlet to conduct a set of basic checks on your AD configuration 
# with the logged on AD user. This cmdlet is supported on AzFilesHybrid v0.1.2+ version. For more details on 
# the checks performed in this cmdlet, see Azure Files Windows troubleshooting guide.
Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose