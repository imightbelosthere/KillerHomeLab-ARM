configuration S16BASESTIG-MOF
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
            OsVersion   = '2016'
            StigVersion = '2.5'
            OsRole = 'MS'
            OrgSettings = 'C:\S16BASESTIG-MOF\WindowsServer-2016-MS-2.5.org.1.0.xml'
            Exception   = @{
                'V-224038'= @{
                    'ValueData'='0'
                }
                'V-225015'= @{
                    'Identity'='Guests'
                }
                'V-225019'= @{
                    'Identity'='Guests'
                }
            }
        }
    }
}

S16BASESTIG-MOF -OutputPath C:\S16BASESTIG-MOF -Verbose