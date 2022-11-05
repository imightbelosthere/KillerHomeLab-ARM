configuration ENABLESQLALWAYSON
{
   param
   (     
        [String]$NetBiosDomain,
        [System.Management.Automation.PSCredential]$InstallAccountCreds
    )

    Import-DscResource -Module SqlServerDsc # Used for SQL Objects

    [System.Management.Automation.PSCredential ]$SQLInstallCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($InstallAccountCreds.UserName)", $InstallAccountCreds.Password)

    Node localhost
    {
        SqlAlwaysOnService EnableSQLAlwaysOn
        {
            InstanceName = "MSSQLSERVER"
            Ensure = "Present"
            RestartTimeout = 120
            PsDscRunAsCredential = $SQLInstallCreds
        }
    }
}