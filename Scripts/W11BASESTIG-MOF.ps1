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
            OrgSettings = 'C:\W11BASESTIG-MOF\WindowsClient-11-1.2.org.1.0.xml'
            Exception   = @{
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

W11BASESTIG-MOF -OutputPath C:\W11BASESTIG-MOF -Verbose