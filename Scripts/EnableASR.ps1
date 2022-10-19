Param(
    [string] [Parameter(Mandatory=$true)] $RSVaultName,
    [string] [Parameter(Mandatory=$true)] $RecoveryVNetName,
    [string] [Parameter(Mandatory=$true)] $DEDESName,
    [string] [Parameter(Mandatory=$true)] $Site1Name,
    [string] [Parameter(Mandatory=$true)] $Site2Name,
    [string] [Parameter(Mandatory=$true)] $SourceRG,
    [string] [Parameter(Mandatory=$true)] $TargetRG,    
    [string] [Parameter(Mandatory=$true)] $Location1,
    [string] [Parameter(Mandatory=$true)] $Location2,
    [string] [Parameter(Mandatory=$true)] $vmName
)

# -----------------------------------------------------------------------------------------------------------------
# Get Virtual Machine Information
# -----------------------------------------------------------------------------------------------------------------
$VM = Get-AzVM -ResourceGroupName $SourceRG -Name $vmname
$des = Get-AzDiskEncryptionSet -Name $DEDESName -ResourceGroupName $TargetRG
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Set Recovery Services Vault Context
# -----------------------------------------------------------------------------------------------------------------
$VaultForSite1 = Get-AzRecoveryServicesVault -Name $RSVaultName -ResourceGroupName $TargetRG -ErrorAction 0
Set-AzRecoveryServicesVaultProperty -SoftDeleteFeatureState Disable -VaultId $VaultForSite1.ID
Set-AzRecoveryServicesAsrVaultContext -Vault $VaultForSite1
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Create Primary ASR fabric
# -----------------------------------------------------------------------------------------------------------------
$PrimaryFabricCheck = Get-AzRecoveryServicesAsrFabric -Name $Site1Name-ASR-Fabric -ErrorAction 0
IF ($null -eq $PrimaryFabricCheck) {$TempASRJob = New-AzRecoveryServicesAsrFabric -Azure -Location $Location1  -Name $Site1Name-ASR-Fabric}
ELSE {$TempASRJob = Get-AzRecoveryServicesAsrFabric -Name $Site1Name-ASR-Fabric}

# Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        #If the job hasn't completed, sleep for 10 seconds before checking the job status again
        Start-Sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $Site1Name-ASR-Fabric
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Create Recovery ASR fabric
# -----------------------------------------------------------------------------------------------------------------
$RecoveryFabricCheck = Get-AzRecoveryServicesAsrFabric -Name $Site2Name-ASR-Fabric -ErrorAction 0
IF ($null -eq $RecoveryFabricCheck) {$TempASRJob = New-AzRecoveryServicesAsrFabric -Azure -Location $Location2  -Name $Site2Name-ASR-Fabric}
ELSE {$TempASRJob = Get-AzRecoveryServicesAsrFabric -Name $Site2Name-ASR-Fabric}

# Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        Start-Sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$RecoveryFabric = Get-AzRecoveryServicesAsrFabric -Name $Site2Name-ASR-Fabric
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Create a Protection container in the primary Azure region (within the Primary fabric)
# -----------------------------------------------------------------------------------------------------------------
$PrimaryContainerCheck = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $Site1Name-ProtectionContainer -ErrorAction 0
IF ($null -eq $PrimaryContainerCheck) {$TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $PrimaryFabric -Name $Site1Name-ProtectionContainer}
ELSE {$TempASRJob = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $Site1Name-ProtectionContainer}

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        Start-Sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

Write-Output $TempASRJob.State

$PrimaryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $Site1Name-ProtectionContainer
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Create a Protection container in the recovery Azure region (within the Recovery fabric)
# -----------------------------------------------------------------------------------------------------------------
$RecoveryContainerCheck = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name $Site2Name-ProtectionContainer -ErrorAction 0
IF ($null -eq $RecoveryContainerCheck) {$TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $RecoveryFabric -Name $Site2Name-ProtectionContainer}
ELSE {$TempASRJob = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name $Site2Name-ProtectionContainer}

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        Start-Sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"

Write-Output $TempASRJob.State

$RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $RecoveryFabric -Name $Site2Name-ProtectionContainer
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Create replication policy
# -----------------------------------------------------------------------------------------------------------------
$PolicyCheck = Get-AzRecoveryServicesAsrPolicy -Name $Site1Name-Policy -ErrorAction 0
IF ($null -eq $PolicyCheck) {$TempASRJob = New-AzRecoveryServicesAsrPolicy -AzureToAzure -Name $Site1Name-Policy -RecoveryPointRetentionInHours 24 -ApplicationConsistentSnapshotFrequencyInHours 4}
ELSE {$TempASRJob = Get-AzRecoveryServicesAsrPolicy -Name $Site1Name-Policy}

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        Start-Sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name $Site1Name-Policy
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Create Protection container mapping between the Primary and Recovery Protection Containers with the Replication policy
# -----------------------------------------------------------------------------------------------------------------
$Site1ToSite2PCMappingCheck = Get-AzRecoveryServicesAsrProtectionContainerMapping -Name $Site1Name-PrimaryToRecovery -ProtectionContainer $PrimaryProtContainer -ErrorAction 0
IF ($null -eq $Site1ToSite2PCMappingCheck) {$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name $Site1Name-PrimaryToRecovery -Policy $ReplicationPolicy -PrimaryProtectionContainer $PrimaryProtContainer -RecoveryProtectionContainer $RecoveryProtContainer}
ELSE {$TempASRJob = Get-AzRecoveryServicesAsrProtectionContainerMapping -Name $Site1Name-PrimaryToRecovery -ProtectionContainer $PrimaryProtContainer}

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        Start-Sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$Site1ToSite2PCMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $PrimaryProtContainer -Name $Site1Name-PrimaryToRecovery
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Create Protection container mapping (for fail back) between the Recovery and Primary Protection Containers with the Replication policy
# -----------------------------------------------------------------------------------------------------------------
$Site2ToSite1PCMappingCheck = Get-AzRecoveryServicesAsrProtectionContainerMapping -Name $Site2Name-RecoveryToPrimary -ProtectionContainer $RecoveryProtContainer -ErrorAction 0
IF ($null -eq $Site2ToSite1PCMappingCheck) {$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name $Site2Name-RecoveryToPrimary -Policy $ReplicationPolicy -PrimaryProtectionContainer $RecoveryProtContainer -RecoveryProtectionContainer $PrimaryProtContainer}
ELSE {$TempASRJob = Get-AzRecoveryServicesAsrProtectionContainerMapping -Name $Site2Name-RecoveryToPrimary -ProtectionContainer $RecoveryProtContainer}

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        Start-Sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Create Cache storage account for replication logs in the primary region
# -----------------------------------------------------------------------------------------------------------------
$CacheStorageCheck = Get-AzStorageAccount -Name $Site1Name'cachestorage' -ResourceGroupName $SourceRG -ErrorAction 0
IF ($null -eq $CacheStorageCheck) {$Site1CacheStorageAccount = New-AzStorageAccount -Name $Site1Name'cachestorage' -ResourceGroupName $SourceRG -Location $Location1 -SkuName Standard_LRS -Kind Storage}
ELSE {$Site1CacheStorageAccount = Get-AzStorageAccount -Name $Site1Name'cachestorage' -ResourceGroupName $SourceRG}
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Set Recovery Network in the recovery region
# -----------------------------------------------------------------------------------------------------------------
$RecoveryVnet = Get-AzVirtualNetwork -ResourceGroup $TargetRG -Name $RecoveryVNetName
$RecoveryNetwork = $RecoveryVnet.Id
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Retrieve the virtual network that the virtual machine is connected to
# -----------------------------------------------------------------------------------------------------------------
# Get first network interface card(nic) of the virtual machine
$SplitNicArmId = $VM.NetworkProfile.NetworkInterfaces[0].Id.split("/")

#Extract resource name from the ResourceId of the nic
$NICname = $SplitNicArmId[-1]

#Get network interface details using the extracted resource group name and resource name
$NIC = Get-AzNetworkInterface -ResourceGroupName $SourceRG -Name $NICname

#Get the subnet ID of the subnet that the nic is connected to
$PrimarySubnet = $NIC.IpConfigurations[0].Subnet

# Extract the resource ID of the Azure virtual network the nic is connected to from the subnet ID
$PrimaryNetwork = (Split-Path(Split-Path($PrimarySubnet.Id))).Replace("\","/")
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Create an ASR network mapping between the primary Azure virtual network and the recovery Azure virtual network
# -----------------------------------------------------------------------------------------------------------------
$Site1ToSite2NWMappingCheck = Get-AzRecoveryServicesAsrNetworkMapping -Name $Site1Name-NWMapping -PrimaryFabric $PrimaryFabric -ErrorAction 0
IF ($Site1ToSite2NWMappingCheck -eq $null) {$TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name $Site1Name-NWMapping -PrimaryFabric $PrimaryFabric -PrimaryAzureNetworkId $PrimaryNetwork -RecoveryFabric $RecoveryFabric -RecoveryAzureNetworkId $RecoveryNetwork}
ELSE {$TempASRJob = Get-AzRecoveryServicesAsrNetworkMapping -Name $Site1Name-NWMapping -PrimaryFabric $PrimaryFabric}

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
# Create an ASR network mapping for fail back between the recovery Azure virtual network and the primary Azure virtual network
# -----------------------------------------------------------------------------------------------------------------
$Site2ToSite1NWMappingCheck = Get-AzRecoveryServicesAsrNetworkMapping -Name $Site2Name-NWMapping -PrimaryFabric $RecoveryFabric -ErrorAction 0
IF ($Site2ToSite1NWMappingCheck -eq $null) {$TempASRJob = New-AzRecoveryServicesAsrNetworkMapping -AzureToAzure -Name $Site2Name-NWMapping -PrimaryFabric $RecoveryFabric -PrimaryAzureNetworkId $RecoveryNetwork -RecoveryFabric $PrimaryFabric -RecoveryAzureNetworkId $PrimaryNetwork}
ELSE {$TempASRJob = Get-AzRecoveryServicesAsrNetworkMapping -Name $Site2Name-NWMapping -PrimaryFabric $RecoveryFabric}

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        Start-Sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State
# ________________________________________________________________________________________________________________

# -----------------------------------------------------------------------------------------------------------------
#Get the resource group that the virtual machine must be created in when failed over.
# -----------------------------------------------------------------------------------------------------------------
$RecoveryRG = Get-AzResourceGroup -Name $TargetRG -Location $Location2

#Specify replication properties for each disk of the VM that is to be replicated (create disk replication configuration)
#OsDisk
$OSdiskId = $vm.StorageProfile.OsDisk.ManagedDisk.Id
$RecoveryOSDiskAccountType = $vm.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
$OSRecoveryReplicaDiskAccountType = $vm.StorageProfile.OsDisk.ManagedDisk.StorageAccountType

$OSDiskReplicationConfig = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -LogStorageAccountId $Site1CacheStorageAccount.Id `
         -DiskId $OSdiskId -RecoveryResourceGroupId  $RecoveryRG.ResourceId -RecoveryReplicaDiskAccountType $OSRecoveryReplicaDiskAccountType `
         -RecoveryTargetDiskAccountType $RecoveryOSDiskAccountType -RecoveryDiskEncryptionSetId $DES.Id

    $DataDiskCount = ($vm.StorageProfile.DataDisks).Count
    $DataDisks = $vm.StorageProfile.DataDisks
    IF ($DataDiskCount -ne 0){
    $DataDiskReplicationConfigs = @()
    foreach ($DataDisk in $DataDisks){
        $datadiskId = $DataDisk.ManagedDisk.Id
        $DataDiskAccountType = $DataDisk.ManagedDisk.StorageAccountType

        $DataDisk1ReplicationConfig  += New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -LogStorageAccountId $Site1CacheStorageAccount.Id `
                 -DiskId $datadiskId -RecoveryResourceGroupId $RecoveryRG.ResourceId -RecoveryReplicaDiskAccountType $DataDiskAccountType `
                 -RecoveryTargetDiskAccountType $DataDiskAccountType -RecoveryDiskEncryptionSetId $DES.Id                 
        }
    #Create a list of disk replication configuration objects for the disks of the virtual machine that are to be replicated.
        $diskconfigs = @()
        $diskconfigs += $OSDiskReplicationConfig
        $diskconfigs += $DataDiskReplicationConfigs
        }
        ELSE {
                $diskconfigs = @()
                $diskconfigs += $OSDiskReplicationConfig
        }

$protecteditemcheck = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryProtContainer -ErrorAction 0
IF ($null -eq $protecteditemcheck) {New-AzRecoveryServicesAsrReplicationProtectedItem -AzureToAzure -AzureVmId $VM.Id -Name (New-Guid).Guid -ProtectionContainerMapping $Site1ToSite2PCMapping -AzureToAzureDiskReplicationConfiguration $diskconfigs -RecoveryResourceGroupId $RecoveryRG.ResourceId}    

# Data disk
# $DataDiskCheck = $vm.StorageProfile.DataDisks
# IF ($null -ne $DataDiskCheck){
# $datadiskId1 = $vm.StorageProfile.DataDisks[0].ManagedDisk.Id
# $RecoveryReplicaDiskAccountType = $vm.StorageProfile.DataDisks[0].ManagedDisk.StorageAccountType
# $DataRecoveryTargetDiskAccountType = $vm.StorageProfile.DataDisks[0].ManagedDisk.StorageAccountType

# $DataDisk1ReplicationConfig  = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -LogStorageAccountId $Site1CacheStorageAccount.Id `
#          -DiskId $datadiskId1 -RecoveryResourceGroupId $RecoveryRG.ResourceId -RecoveryReplicaDiskAccountType $DataRecoveryReplicaDiskAccountType `
#          -RecoveryTargetDiskAccountType $RecoveryTargetDiskAccountType -RecoveryDiskEncryptionSetId $DES.Id

#Create a list of disk replication configuration objects for the disks of the virtual machine that are to be replicated.
# $diskconfigs = @()
# $diskconfigs += $OSDiskReplicationConfig, $DataDisk1ReplicationConfig
# }
# ELSE {
# $diskconfigs = @()
# $diskconfigs += $OSDiskReplicationConfig
# }

#Start replication by creating replication protected item. Using a GUID for the name of the replication protected item to ensure uniqueness of name.
# $protecteditemcheck = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryProtContainer -ErrorAction 0
# IF ($null -eq $protecteditemcheck) {New-AzRecoveryServicesAsrReplicationProtectedItem -AzureToAzure -AzureVmId $VM.Id -Name (New-Guid).Guid -ProtectionContainerMapping $Site1ToSite2PCMapping -AzureToAzureDiskReplicationConfiguration $diskconfigs -RecoveryResourceGroupId $RecoveryRG.ResourceId}
# ________________________________________________________________________________________________________________