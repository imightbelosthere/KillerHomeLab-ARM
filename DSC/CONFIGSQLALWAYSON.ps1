configuration CONFIGSQLALWAYSON
{
   param
   (
        [String]$SQLAGName,     
        [String]$SQLAPName,     
        [String]$SQLAPIP,     
        [String]$SQLNode1,     
        [String]$SQLNode2, 
        [String]$SQLDBName,
        [String]$SQLServiceAccount,                     
        [String]$NetBiosDomain,
        [String]$DomainName,
        [String]$StorageAccountName,
        [String]$StorageAccountKey,
        [String]$StorageEndpoint,        
        [System.Management.Automation.PSCredential]$Admincreds,
        [System.Management.Automation.PSCredential]$SQLAdminAccountCreds
    )

    Import-DscResource -Module SqlServerDsc # Used for SQL Object Creation

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)
    [System.Management.Automation.PSCredential ]$SQLAdminDomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($SQLAdminAccountCreds.UserName)", $SQLAdminAccountCreds.Password)

    Node localhost
    {
        File SQLBackup
        {
            Type = 'Directory'
            DestinationPath = 'C:\SQLBackup'
            Ensure = "Present"
        }

        Script CreateAzureFSW
        {
            SetScript =
            {
		        # Create Cloud Storage Account
                $CloudWitness = Get-ClusterQuorum | Where-Object {$_.QuorumResource -like "Cloud Witness"}
		        IF ($CloudWitness -eq $null) {Set-ClusterQuorum -CloudWitness -AccountName "$using:StorageAccountName" -AccessKey "$using:StorageAccountKey" -EndPoint "$using:StorageEndPoint"}
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $SQLAdminDomainCreds
        }

        SqlDatabase CreateSQLDatabase
        {
            Name = $SQLDBName
            InstanceName = "MSSQLSERVER"
            Ensure = "Present"
            RecoveryModel = "Full"
            PsDscRunAsCredential = $SQLAdminDomainCreds
        }

        Script BackupRestoreDB
        {
            SetScript =
            {
                # Variables
                $SQLSvc = "$using:NetBiosDomain\$using:SQLServiceAccount"
                
                # Create Shares
                $BackupShare = Get-SmbShare -Name SQLBackup -ErrorAction 0
                IF ($Backupshare -eq $null) {New-SmbShare -Name SQLBackup -Path C:\SQLBackup -FullAccess "$SQLSvc",Administrators}
               
                # Backup Database
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
                $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$using:SQLNode1"
                $database = $Server.Databases | Where-Object {$_.Name -like "$using:SQLDBName"}
                IF ($database.LastBackupDate -like "*0001*") {
                
                Backup-SqlDatabase -Database "$using:SQLDBName" -BackupFile "\\$using:SQLNode1\SQLBackup\$using:SQLDBName.bak" -ServerInstance "$using:SQLNode1"
                Backup-SqlDatabase -Database "$using:SQLDBName" -BackupFile "\\$using:SQLNode1\SQLBackup\$using:SQLDBName.log" -ServerInstance "$using:SQLNode1" -BackupAction Log

                # Restore the database and log on the secondary (using NO RECOVERY)  
                Restore-SqlDatabase -Database "$using:SQLDBName" -BackupFile "\\$using:SQLNode1\SQLBackup\$using:SQLDBName.bak" -ServerInstance "$using:SQLNode2" -NoRecovery
                Restore-SqlDatabase -Database "$using:SQLDBName" -BackupFile "\\$using:SQLNode1\SQLBackup\$using:SQLDBName.log" -ServerInstance "$using:SQLNode2" -RestoreAction Log -NoRecovery
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $AdminCreds
            DependsOn = '[File]SQLBackup', '[SqlDatabase]CreateSQLDatabase'
        }

        SqlEndpoint CreateSQL1Endpoint
        {
            EndpointName = 'Endpoint1'
            EndpointType = 'DatabaseMirroring'
            Ensure = "Present"
            Port = 5022
            ServerName = $SQLNode1
            InstanceName = "MSSQLSERVER"
            PsDscRunAsCredential = $AdminCreds
            DependsOn = '[File]SQLBackup', '[SqlDatabase]CreateSQLDatabase', '[Script]BackupRestoreDB'
        }

        SqlEndpoint CreateSQL2Endpoint
        {
            EndpointName = 'Endpoint2'
            EndpointType = 'DatabaseMirroring'
            Ensure = "Present"
            Port = 5022
            ServerName = $SQLNode2
            InstanceName = "MSSQLSERVER"
            PsDscRunAsCredential = $AdminCreds
            DependsOn = '[File]SQLBackup', '[SqlDatabase]CreateSQLDatabase', '[Script]BackupRestoreDB'
        }

        SqlAG CreateSQLAG
        {
            Name = $SQLAGName
            ServerName = $SQLNode1
            InstanceName = "MSSQLSERVER"
            Ensure = "Present"
            AvailabilityMode = "SynchronousCommit"
            FailoverMode = "Automatic"
            EndpointHostName = "$SQLNode1.$DomainName"
            DependsOn = '[SqlEndpoint]CreateSQL1Endpoint','[SqlEndpoint]CreateSQL2Endpoint'
        }

        SqlAGReplica AddNodetoSQLAG
        {
            Ensure = "Present"
            Name = "$SQLNode2"
            AvailabilityGroupName = $SQLAGName
            ServerName = $SQLNode2
            InstanceName = "MSSQLSERVER"
            PrimaryReplicaServerName = $SQLNode1
            PrimaryReplicaInstanceName = "MSSQLSERVER"
            AvailabilityMode = "SynchronousCommit"
            FailoverMode = "Automatic"
            EndpointHostName = "$SQLNode2.$DomainName"
            PsDscRunAsCredential = $AdminCreds
            DependsOn = '[SqlEndpoint]CreateSQL1Endpoint','[SqlEndpoint]CreateSQL2Endpoint', '[SqlAG]CreateSQLAG'
        }

        Script GrantSQLSvcConnect
        {
            SetScript =
            {
                # Variables
                $SQLSvc = "$using:NetBiosDomain\$using:SQLServiceAccount"
                $endpointName1 = "Endpoint1"
                $endpointName2 = "Endpoint2"
                $endpointAccount = "$SQLSvc"

                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
                $server1 = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$using:SQLNode1"
                $endpoint1 = $server1.Endpoints[$endpointName1]

                $server2 = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$using:SQLNode2"
                $endpoint2 = $server2.Endpoints[$endpointName2]

                #identify the Connect permission object
                $permissionSet1 = New-Object Microsoft.SqlServer.Management.Smo.ObjectPermissionSet([Microsoft.SqlServer.Management.Smo.ObjectPermission]::Connect)
                $permissionSet2 = New-Object Microsoft.SqlServer.Management.Smo.ObjectPermissionSet([Microsoft.SqlServer.Management.Smo.ObjectPermission]::Connect)

                #grant permission
                $endpoint1.Grant($permissionSet1,$endpointAccount)                
                $endpoint2.Grant($permissionSet2,$endpointAccount)                
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $SQLAdminDomainCreds
            DependsOn = '[SqlAGReplica]AddNodetoSQLAG'
        }

        SqlAGDatabase AddSQLAGDatabase
        {
            DatabaseName = $SQLDBName
            ServerName = $SQLNode1
            InstanceName = "MSSQLSERVER"
            AvailabilityGroupName = $SQLAGName
            BackupPath = "\\$SQLNode1\SQLBackup\"
            Ensure = "Present"
            DependsOn = '[SqlAGReplica]AddNodetoSQLAG'
            PsDscRunAsCredential = $SQLAdminDomainCreds
        }

        Script CreateSQLAGListener
        {
            SetScript =
            {
                # Create Client Access Point
                $SQLAPIPName = "$using:SQLAPName"+'-IP'             
                $NetworkName = Get-ClusterResource -Name "$using:SQLAPName" -ErrorAction 0
                IF ($NetworkName -eq $Null) {
                
                # Stop Role
                $Cluster = Get-ClusterNetwork | Where-Object {$_.Role -like 'ClusterAndClient'}
                $ClusterName = $Cluster.Name
                Stop-ClusterResource "$using:SQLAGName"

                # Add Cluste Network Name
                Add-ClusterResource -Name "$using:SQLAPName" -Type "Network Name" -Group "$using:SQLAGName"

                # Set Cluster IP Parameters
                Get-ClusterResource "$using:SQLAPName" | Set-ClusterParameter -Multiple @{"Name"="$using:SQLAPName";"DnsName"="$using:SQLAPName"}

                # Add Cluster IP
                Add-ClusterResource -Name $SQLAPIPName -Type "IP Address" -Group "$using:SQLAGName"

                # Set Cluster IP Parameters
                Get-ClusterResource $SQLAPIPName | Set-ClusterParameter -Multiple @{"Address"="$using:SQLAPIP";"ProbePort"="59999";"SubnetMask"="255.255.255.255";"Network"="$ClusterName";"EnableDhcp"=0}

                # Set Dependencies
                Set-ClusterResourceDependency -Resource "$using:SQLAGName" -Dependency "[$using:SQLAPName]"
                Set-ClusterResourceDependency -Resource "$using:SQLAPName" -Dependency "[$SQLAPIPName]"

                # Start Role
                Start-ClusterResource "$using:SQLAGName"
                }

            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $SQLAdminDomainCreds
            DependsOn = '[SqlAGDatabase]AddSQLAGDatabase'
        }
    }
}