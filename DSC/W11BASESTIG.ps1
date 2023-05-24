configuration W11BASESTIG
{

    Import-DscResource -Module PowerSTIG

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
                winrm quickconfig -force\

                Install-PackageProvider -Name NuGet -Force
                Install-Module PowerSTIG -Force
                Import-Module PowerSTIG
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]EnableTls12'
        }

        WindowsClient BaseLine
        {
            OsVersion   = '11'
            StigVersion = '1.2'
            OrgSettings = 'C:\Program Files\WindowsPowerShell\Modules\PowerSTIG.zip\PowerSTIG\4.16.0\StigData\Processed\WindowsClient-11-1.2.org.default.xml'
            Exception   = @{
                'V-253369.b'= @{
                    'ValueData'='0'
                }
                'V-253371'= @{
                    'ValueData'='0'
                }
                'V-253448'= @{
                    'ValueData'='0'
                }
                'V-253363'= @{
                    'ValueData'='curve25519;NistP256;NistP384'
                }
                'V-253491'= @{
                    'Identity'='Guests'
                }
                'V-253495'= @{
                    'Identity'='Guests'
                }
            }
        }
    }
}