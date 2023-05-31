configuration EDGESTIG-MOF
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
        Edge BaseLine
        {
            StigVersion = '1.6'
            OrgSettings = 'C:\EDGESTIG-MOF\MS-Edge-1.6.org.1.0.xml'
        }
    }
}

EDGESTIG-MOF -OutputPath C:\EDGESTIG-MOF -Verbose