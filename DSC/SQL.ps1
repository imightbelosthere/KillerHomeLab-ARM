Configuration SQL
{
   param
   (
        [String]$SQLSASUrl,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module SqlServerDsc # Used for SQL
    Import-DscResource -Module xStorage # Used for ISO
    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemote

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

        xWaitforDisk Disk2
        {
             DiskId = 2
             RetryIntervalSec = 60
             RetryCount = 60
        }

        xDisk SVolume
        {
             DiskId = 2
             DriveLetter = 'S'
             DependsOn = '[xWaitForDisk]Disk2'
        }
        
        xWaitforVolume WaitForSVolume
        {
             DriveLetter = 'S'
             RetryIntervalSec = 60
             RetryCount = 60
        }

        xWaitforDisk Disk3
        {
             DiskId = 3
             RetryIntervalSec = 60
             RetryCount = 60
        }

        xDisk LVolume
        {
             DiskId = 3
             DriveLetter = 'L'
             DependsOn = '[xWaitForDisk]Disk3'
        }
        
        xWaitforVolume WaitForLVolume
        {
             DriveLetter = 'L'
             RetryIntervalSec = 60
             RetryCount = 60
        }

        File SQLSoftware
        {
            Type = 'Directory'
            DestinationPath = 'C:\SQLSoftware'
            Ensure = "Present"
        }

        File SQLDatabase
        {
            Type = 'Directory'
            DestinationPath = 'S:\SQLDatabases'
            Ensure = "Present"
        }

        File SQLLogs
        {
            Type = 'Directory'
            DestinationPath = 'L:\SQLLogs'
            Ensure = "Present"
        }

        xRemoteFile SqlDownload
        {
            DestinationPath = "C:\SQLSoftware\SQL.iso"
            Uri             = "$SQLSASUrl"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn =    "[File]SQLSoftware"
        }

        xMountImage MountSQLISO
        {
            ImagePath   = 'C:\SQLSoftware\SQL.iso'
            DriveLetter = 'I'
            DependsOn = '[xRemoteFile]SqlDownload'
        }

        xWaitForVolume WaitForISO
        {
            DriveLetter      = 'I'
            RetryIntervalSec = 5
            RetryCount       = 10
            DependsOn = '[xMountImage]MountSQLISO'
        }

        SqlSetup 'InstallDefaultInstance'
        {
            InstanceName        = 'MSSQLSERVER'
            Features            = 'SQLENGINE'
            SourcePath          = 'I:\'
            SQLSysAdminAccounts = @('Administrators')
            DependsOn           = '[xWaitForVolume]WaitForISO'
            SQLUserDBDir        = 'S:\SQLDatabases'
            SQLUserDBLogDir     = 'L:\SQLLogs'
          }
     }
  }