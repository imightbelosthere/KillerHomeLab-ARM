configuration ENABLESQLALWAYSON
{
   param
   (     
        [String]$NetBiosDomain,
        [System.Management.Automation.PSCredential]$SQLAdminAccountCreds
    )

    Import-DscResource -Module SqlServerDsc # Used for SQL Objects

    [System.Management.Automation.PSCredential ]$SQLAdminDomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($SQLAdminAccountCreds.UserName)", $SQLAdminAccountCreds.Password)

    Node localhost
    {
        SqlAlwaysOnService EnableSQLAlwaysOn
        {
            InstanceName = "MSSQLSERVER"
            Ensure = "Present"
            RestartTimeout = 120
            PsDscRunAsCredential = $SQLAdminDomainCreds
        }
    }
}