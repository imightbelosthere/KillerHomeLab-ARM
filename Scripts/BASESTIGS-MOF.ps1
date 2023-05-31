configuration W11BASESTIG-MOF
{
    param
    (
        [parameter()]
        [string]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName PowerStig

    Node $NodeName
    {
        WindowsClient BaseLine
        {
            OsVersion   = '11'
            StigVersion = '1.2'
            OrgSettings = 'C:\STIGS\WindowsClient-11-1.2.org.1.0.xml'
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

        WindowsDefender BaseLine
        {
            StigVersion = '2.4'
            OrgSettings = 'C:\STIGS\WindowsDefender-All-2.4.org.1.0.xml'
            DependsOn = '[WindowsClient]BaseLine'
        }

        WindowsFirewall BaseLine
        {
            StigVersion = '2.1'
            OrgSettings = 'C:\STIGS\WindowsFirewall-All-2.1.org.1.0.xml'
            DependsOn = '[WindowsDefender]BaseLine'
        }
    }
}

W11BASESTIG-MOF -OutputPath C:\STIGS -Verbose