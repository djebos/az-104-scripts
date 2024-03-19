# Install-Module Az -Force
# Connect-AzAccount -Tenant e3f1b00d-ea6f-4c5a-9d70-f2f5945431e9

Select-AzSubscription -SubscriptionName firstsub


$resourceGroup = "storage-redundancy-live-migration"
$location = "eastus"

New-AzResourceGroup -Name $resourceGroup `
  -Location $location `
  -Tag @{topic="3"; question="12"} `
  -Confirm

New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage1 `
  -Location $location `
  -SkuName Premium_LRS `
  -Kind Storage `
  -AllowBlobPublicAccess $false `
  -AsJob

  # not supported
  # New-AzStorageAccount -ResourceGroupName $resourceGroup `
  # -Name djeb0storage15 `
  # -Location $location `
  # -SkuName Premium_ZRS `
  # -Kind Storage `
  # -AllowBlobPublicAccess $false `
  # -AsJob

  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage2 `
  -Location $location `
  -SkuName Standard_ZRS `
  -Kind Storage `
  -AllowBlobPublicAccess $false `
  -AsJob

  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage3 `
  -Location $location `
  -SkuName Standard_RAGRS `
  -Kind Storage `
  -AllowBlobPublicAccess $false `
  -AsJob

  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage10 `
  -Location $location `
  -SkuName Standard_GRS `
  -Kind Storage `
  -AllowBlobPublicAccess $false `
  -AsJob

  # Not supported
  # New-AzStorageAccount -ResourceGroupName $resourceGroup `
  # -Name djeb0storage9 `
  # -Location $location `
  # -SkuName Premium_GRS `
  # -Kind Storage `
  # -AllowBlobPublicAccess $false `
  # -AsJob

  # Storage V2 cannot be created with premium sku and GRS/RAGRS replication
  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage4 `
  -Location $location `
  -SkuName Standard_LRS `
  -Kind StorageV2 `
  -AllowBlobPublicAccess $false `
  -AccessTier Cool `
  -AsJob

  # Storage V2 cannot be created with premium sku and GRS/RAGRS replication
  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage5 `
  -Location $location `
  -SkuName Standard_RAGRS `
  -Kind StorageV2 `
  -AllowBlobPublicAccess $false `
  -AccessTier Hot `
  -AsJob
  
  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage11 `
  -Location $location `
  -SkuName Premium_LRS `
  -Kind StorageV2 `
  -AllowBlobPublicAccess $false `
  -AccessTier Hot `
  -AsJob

  #Premium tiers and ZRS isn't supported for BlobStorage
  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage6 `
  -Location $location `
  -SkuName Standard_LRS `
  -Kind BlobStorage `
  -AllowBlobPublicAccess $false `
  -AccessTier Hot `
  -AsJob

  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage13 `
  -Location $location `
  -SkuName Standard_GRS `
  -Kind BlobStorage `
  -AllowBlobPublicAccess $false `
  -AccessTier Hot `
  -AsJob

  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage14 `
  -Location $location `
  -SkuName Standard_RAGRS `
  -Kind BlobStorage `
  -AllowBlobPublicAccess $false `
  -AccessTier Hot `
  -AsJob

  # Standard tiers aren't supported because BlockBlobkStorage is Premium by default, RA-GRS, GRS, GRZS not supported due to latency?
  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage7 `
  -Location $location `
  -SkuName Premium_LRS `
  -Kind BlockBlobStorage `
  -AllowBlobPublicAccess $false `
  -AsJob

  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage12 `
  -Location $location `
  -SkuName Premium_ZRS `
  -Kind BlockBlobStorage `
  -AllowBlobPublicAccess $false

  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage8 `
  -Location $location `
  -SkuName Premium_ZRS `
  -Kind FileStorage `
  -AllowBlobPublicAccess $false `
  -AsJob

  New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name djeb0storage16 `
  -Location $location `
  -SkuName Premium_LRS `
  -Kind FileStorage `
  -AllowBlobPublicAccess $false `
  -AsJob

  

# Get all jobs
$allJobs = Get-Job

# Wait for all jobs to complete
Wait-Job -Job $allJobs