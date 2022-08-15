Configuration SSMS
{
    Import-DscResource -ModuleName xPSDesiredStateConfiguration # Used for xRemote

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

        File SQLSoftware
        {
            Type = 'Directory'
            DestinationPath = 'C:\SQLSoftware'
            Ensure = "Present"
        }

        xRemoteFile SSMS
        {
            DestinationPath = 'C:\SQLSoftware\SSMS-Setup-ENU.exe'
            Uri             = "https://aka.ms/SSMSFullSetup"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn =    "[File]SQLSoftware"
        }

        Script InstallSQLManagementStudio
        {
            SetScript =
            {
                # Install SQL Management Studio
                Start-Process "C:\SQLSoftware\SSMS-Setup-ENU.exe" -ArgumentList "/install /quiet /norestart" -Wait

                $EnableSQL = Get-NetFirewallRule "SQL-In-TCP" -ErrorAction 0
                IF ($EnableSQL -eq $null) {New-NetFirewallRule -DisplayName "SQL-In-TCP" -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow}
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]SSMS'
        }
     }
  }