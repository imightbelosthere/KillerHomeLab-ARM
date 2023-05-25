configuration W11BASESTIG
{
    Node localhost
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = "StopConfiguration"
            ConfigurationMode = "ApplyOnly"
        }

        Script EnableTls12
        {
            SetScript =
            {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

        Script ConfigWinRM
        {
            SetScript =
            {
                Set-Service -Name "WinRM" -StartupType Automatic
                Start-Service -Name "WinRM"
                $Interface=Get-NetAdapter|Where-Object Name -Like "Ethernet*"|Select-Object -First 1
                $InterfaceAlias=$($Interface.Name)
                Set-NetConnectionProfile -InterfaceAlias $InterfaceAlias -NetworkCategory Private
                Set-Item -Path WSMan:\localhost\MaxEnvelopeSizekb -Value 8192
                Enable-PSRemoting –Force

                Install-PackageProvider -Name NuGet -Force
                Install-Module PowerSTIG -Force
                Import-Module PowerSTIG
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]EnableTls12'
        }
    }
}