configuration W10BASESTIG-MOF
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
            OsVersion   = '10'
            StigVersion = '2.5'
            OrgSettings = 'C:\W10BASESTIG-MOF\WindowsClient-10-2.5.org.1.0.xml'
            Exception   = @{
                'V-220811'= @{
                    'ValueData'='0'
                }
                'V-220924'= @{
                    'ValueData'='0'
                }
                'V-220805'= @{
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

W10BASESTIG-MOF -OutputPath C:\W10BASESTIG-MOF -Verbose