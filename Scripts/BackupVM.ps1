Param(
    [string]$BackupPolicyName,
    [string]$RSVaultName,
    [string]$ResourceGroupName,
    [string]$vmName
)

# Get Recovery Services Vault Information
$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $RSVaultName

# Set Recovery Services Vault to use Geo Redundancy
Set-AzRecoveryServicesBackupProperty -Vault $targetVault -BackupStorageRedundancy GeoRedundant

# Get Backup Policy
$schPol = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType "AzureVM"
$UtcTime = Get-Date -Date "2019-04-06 01:00:00Z"
$UtcTime = $UtcTime.ToUniversalTime()
$schpol.ScheduleRunTimes[0] = $UtcTime

# Get Retention Policy
$retPol = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM"

# Create New Policy if needed
$PolicyCheck = Get-AzRecoveryServicesBackupProtectionPolicy -Name $BackupPolicyName -ErrorAction 0
IF ($PolicyCheck -eq $Null){$pol = New-AzRecoveryServicesBackupProtectionPolicy -Name $BackupPolicyName -WorkloadType "AzureVM" -RetentionPolicy $retPol -SchedulePolicy $schPol -VaultId $targetVault.ID}
ELSE {$pol = Get-AzRecoveryServicesBackupProtectionPolicy -Name $BackupPolicyName}

# Enable Protection
Enable-AzRecoveryServicesBackupProtection -Policy $pol -Name $vmName -ResourceGroupName $ResourceGroupName -VaultId $targetVault.ID