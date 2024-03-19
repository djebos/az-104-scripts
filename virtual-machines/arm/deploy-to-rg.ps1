#Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9
$ErrorActionPreference = "Stop"

Select-AzSubscription -SubscriptionName certification-prep
$rg = 'arm-rg-storage-deploy'
$loc = 'eastus'
New-AzResourceGroup -Name $rg -Location $loc `
   -Tag @{topic = "Compute"; question = "72" } -Force

   # New-AzResourceGroupDeployment -ResourceGroupName $rg -TemplateFile .\rg-storage.json
   New-AzDeployment -TemplateFile .\rg-storage.json -Location eastus -Name deploy-storage322 -Verbose

   # Get details about deployment failures
   #Get-AzLog -CorrelationId f36988d8-45ea-4dd2-a4bc-232122c9bf6d  -DetailedOutput