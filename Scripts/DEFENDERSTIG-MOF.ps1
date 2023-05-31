configuration DEFENDERSTIG-MOF
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
        WindowsDefender BaseLine
        {
            StigVersion = '2.4'
            OrgSettings = 'C:\DEFENDERSTIG-MOF\WindowsDefender-All-2.4.org.1.0.xml'
        }
    }
}

DEFENDERSTIG-MOF -OutputPath C:\DEFENDERSTIG-MOF -Verbose