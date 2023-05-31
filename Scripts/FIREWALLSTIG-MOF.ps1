configuration FIREWALLSTIG-MOF
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
        WindowsFirewall BaseLine
        {
            StigVersion = '2.1'
            OrgSettings = 'C:\FIREWALLSTIG-MOF\WindowsFirewall-All-2.1.org.1.0.xml'
        }
    }
}

FIREWALLSTIG-MOF -OutputPath C:\FIREWALLSTIG-MOF -Verbose