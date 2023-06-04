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
            OsRole = 'MS'
            OrgSettings = 'C:\S22BASESTIG-MOF\WindowsServer-2022-MS-1.1.org.1.0.xml'
            Exception   = @{
                'V-254343'= @{
                    'ValueData'='0'
                }
                'V-254459'= @{
                    'ValueData'='0'
                }
                'V-254421'= @{
                    'Identity'='Guests'
                }
                'V-254425'= @{
                    'Identity'='Guests'
                }
            }
        }
    }
}

S22BASESTIG-MOF -OutputPath C:\S22BASESTIG-MOF -Verbose