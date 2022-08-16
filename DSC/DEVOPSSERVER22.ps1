configuration DEVOPSSERVER22
{
   param
   (
        [String]$computerName, 
        [String]$AzureSQLServerFQDN,                             
        [String]$DevOpsServerSASUrl,                     
        [System.Management.Automation.PSCredential]$AzureCreds
    )

    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile
    Import-DscResource -Module xStorage # Used by Disk

    Node localhost
    {
        Registry SchUseStrongCrypto
        {
            Key                         = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
            ValueName                   = 'SchUseStrongCrypto'
            ValueType                   = 'Dword'
            ValueData                   =  '1'
            Ensure                      = 'Present'
        }

        Registry SchUseStrongCrypto64
        {
            Key                         = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
            ValueName                   = 'SchUseStrongCrypto'
            ValueType                   = 'Dword'
            ValueData                   =  '1'
            Ensure                      = 'Present'
        }

        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        Script DismountISO
        {
      	    SetScript = {
                Dismount-DiskImage "C:\DevOpsServerInstall\DevOpsServer2022.iso" -ErrorAction 0
            }
            GetScript =  { @{} }
            TestScript = { $false }
        }

        File CreateSoftwareFolder
        {
            Type = 'Directory'
            DestinationPath = 'C:\DevOpsServerInstall'
            Ensure = "Present"
        }

        xRemoteFile DownloadDevOpsServer2022
        {
            DestinationPath = "C:\DevOpsServerInstall\DevOpsServer2022.iso"
            Uri             = "$DevOpsServerSASUrl"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn =    '[File]CreateSoftwareFolder'
        }

        xMountImage DevOpsServerISO
        {
            ImagePath   = 'C:\DevOpsServerInstall\DevOpsServer2022.iso'
            DriveLetter = 'I'
            DependsOn = '[xRemoteFile]DownloadDevOpsServer2022'
        }

        xWaitForVolume WaitForISO
        {
            DriveLetter      = 'I'
            RetryIntervalSec = 5
            RetryCount       = 10
        }

        Script ConfigureAzureSQLDatabases
        {
            SetScript =
            {
                # Create Credentials
                $Load = "$using:AzureCreds"
                $Username = $AzureCreds.GetNetworkCredential().Username
                $Password = $AzureCreds.GetNetworkCredential().Password
                $ServerURL = "$using:AzureSQLServerFQDN"
                $SQLCMD = '"C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"'

                # Create SQL Script that Create/Grant DevOps Server Managed Identity Permissions to Master DB
                $masterdbconfig = Get-ChildItem -Path C:\DevOpsServerInstall\masterdb.sql -ErrorAction 0
                IF ($masterdbconfig -eq $null) {                 
                    Set-Content -Path C:\DevOpsServerInstall\masterdb.sql -Value "CREATE USER [$using:computerName] FROM EXTERNAL PROVIDER"
                    Add-Content -Path C:\DevOpsServerInstall\masterdb.sql -Value "ALTER ROLE [dbmanager] ADD MEMBER [$using:computerName]"
                }

                # Create SQL Script that Creates/Grants DevOps Server Managed Identity Permissions to Devops DB
                $devopsdbconfig = Get-ChildItem -Path C:\DevOpsServerInstall\devopsdb.sql -ErrorAction 0
                IF ($devopsdbconfig -eq $null) {                 
                    Set-Content -Path C:\DevOpsServerInstall\devopsdb.sql -Value "CREATE USER [$using:computerName] FROM EXTERNAL PROVIDER"
                    Add-Content -Path C:\DevOpsServerInstall\devopsdb.sql -Value "ALTER ROLE [db_owner] ADD MEMBER [$using:computerName]"
                    Add-Content -Path C:\DevOpsServerInstall\devopsdb.sql -Value "ALTER USER [$using:computerName] WITH DEFAULT_SCHEMA=dbo"
                }

                # Run SQL Script
                $ConfigureDatabases = Get-ChildItem -Path C:\DevOpsServerInstall\ConfigureDatabases.cmd -ErrorAction 0
                IF ($ConfigureDatabases -eq $null) {                 
                    Set-Content -Path C:\DevOpsServerInstall\ConfigureDatabases.cmd -Value "$SQLCMD -S $ServerURL -d master -U $Username -P $Password -G -l 30 -i C:\DevOpsServerInstall\masterdb.sql -o C:\DevOpsServerInstall\masterdb.txt"
                    Add-Content -Path C:\DevOpsServerInstall\ConfigureDatabases.cmd -Value "$SQLCMD -S $ServerURL -d AzureDevOps_Configuration -U $Username -P $Password -G -l 30 -i C:\DevOpsServerInstall\devopsdb.sql -o C:\DevOpsServerInstall\devopsdb1.txt"
                    Add-Content -Path C:\DevOpsServerInstall\ConfigureDatabases.cmd -Value "$SQLCMD -S $ServerURL -d AzureDevOps_DefaultCollection -U $Username -P $Password -G -l 30 -i C:\DevOpsServerInstall\devopsdb.sql -o C:\DevOpsServerInstall\devopsdb2.txt"
                    C:\DevOpsServerInstall\ConfigureDatabases.cmd
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = "[xWaitForVolume]WaitForISO"
        }

        Script InstallDevOpsServer2022Bits
        {
            SetScript =
            {
                # Script Variables
                $TFSConfig = '"C:\Program Files\Azure DevOps Server 2022\Tools\TfsConfig.exe"'
                $ServerURL = "$using:AzureSQLServerFQDN"

                $InstallBits = Get-ChildItem -Path C:\DevOpsServerInstall\InstallDevOpsServerBits.cmd -ErrorAction 0
                IF ($InstallBits -eq $null) {                 
                    Set-Content -Path C:\DevOpsServerInstall\InstallDevOpsServerBits.cmd -Value "I:\AzureDevOps2022_RC1.exe /Silent"
                    C:\DevOpsServerInstall\InstallDevOpsServerBits.cmd
                }

                $Install = Get-ChildItem -Path C:\DevOpsServerInstall\InstallDevOpsServer.cmd -ErrorAction 0
                IF ($Install -eq $null) {                 
                    Set-Content -Path C:\DevOpsServerInstall\InstallDevOpsServer.cmd -Value "$TFSConfig unattend /create /type:NewServerAzure /unattendfile:C:\DevOpsServerInstall\AzureBasic.ini /inputs:SQLInstance=$ServerURL"
                    Add-Content -Path C:\DevOpsServerInstall\InstallDevOpsServer.cmd -Value "$TFSConfig unattend /configure /unattendfile:C:\DevOpsServerInstall\AzureBasic.ini"
                    C:\DevOpsServerInstall\InstallDevOpsServer.cmd
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = "[xWaitForVolume]WaitForISO"
        }
    }
}