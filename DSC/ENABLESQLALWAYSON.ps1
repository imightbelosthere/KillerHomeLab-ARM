configuration ENABLESQLALWAYSON
{
   param
   (     
        [String]$NetBiosDomain,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module SqlServerDsc # Used for SQL Objects

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        SqlAlwaysOnService EnableSQLAlwaysOn
        {
            InstanceName = "MSSQLSERVER"
            Ensure = "Present"
            RestartTimeout = 120
            PsDscRunAsCredential = $DomainCreds
        }
    }
}