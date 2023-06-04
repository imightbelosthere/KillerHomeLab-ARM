configuration S19BASESTIG-MOF
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
            OsVersion   = '2019'
            StigVersion = '2.5'
            OsRole = 'MS'
            OrgSettings = 'C:\S19BASESTIG-MOF\WindowsServer-2019-MS-2.5.org.1.0.xml'
            Exception   = @{
                'V-93287'= @{
                    'ValueData'='0'
                }
                'V-93009'= @{
                    'Identity'='Guests'
                }
                'V-92965'= @{
                    'Identity'='Guests'
                }
            }
        }
    }
}

S19BASESTIG-MOF -OutputPath C:\S19BASESTIG-MOF -Verbose