Configuration SQLCMD
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

        File SQLSoftware
        {
            Type = 'Directory'
            DestinationPath = 'C:\SQLSoftware'
            Ensure = "Present"
        }

        xRemoteFile SQLCMD
        {
            DestinationPath = 'C:\SQLSoftware\MsSqlCmdLnUtils.msi'
            Uri             = "https://go.microsoft.com/fwlink/?linkid=2142258"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn =    "[File]SQLSoftware"
        }

        Script InstallSQLCommandLine
        {
            SetScript =
            {
                # Install SQL Command Line
                Start-Process "C:\SQLSoftware\MsSqlCmdLnUtils.msi" -ArgumentList "/quiet IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES" -Wait
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]SQLCMD'
        }
     }
  }