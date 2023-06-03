configuration S22BASESTIG-MOF
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
        WindowsServer BaseLine
        {
            OsVersion   = '11'
            StigVersion = '1.1'
            OrgSettings = 'C:\S22BASESTIG-MOF\WindowsClient-11-1.2.org.1.0.xml'
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

S22BASESTIG-MOF -OutputPath C:\S22BASESTIG-MOF -Verbose