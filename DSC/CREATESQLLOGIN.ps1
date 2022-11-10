configuration CREATESQLLOGIN
{
   param
   (
        [String]$computerName,
        [String]$SQLAdminAccount,
        [String]$NetBiosDomain,
        [String]$DomainName,
        [System.Management.Automation.PSCredential]$Admincreds,
        [System.Management.Automation.PSCredential]$ServiceAccountCreds
    )

    [System.Management.Automation.PSCredential ]$Sqlsvc = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($ServiceAccountCreds.UserName)", $ServiceAccountCreds.Password)
    $ServiceAccount = $ServiceAccountCreds.UserName

    Import-DscResource -Module SqlServerDsc # Used for SQL Configurations

    Node localhost
    {
        SqlLogin CreateSQLAdminSQLLogin
        {
            Ensure               = 'Present'
            Name                 = "$NetBiosDomain\$SQLAdminAccount"
            LoginType            = 'WindowsUser'
            ServerName           = "$ComputerName.$DomainName"
            InstanceName         = 'MSSQLSERVER'
            PsDscRunAsCredential = $Admincreds
        }

        SqlLogin CreateSQLSvcSQLLogin
        {
            Ensure               = 'Present'
            Name                 = "$NetBiosDomain\$ServiceAccount"
            LoginType            = 'WindowsUser'
            ServerName           = "$ComputerName.$DomainName"
            InstanceName         = 'MSSQLSERVER'
            PsDscRunAsCredential = $Admincreds
        }

        Script GrantSysAdmin
        {
            SetScript =
            {
                $RawAccount = "$using:NetBiosDomain\$using:SQLAdminAccount"
                $Account = "'"+$RawAccount+"'"
                $Role = "'sysadmin'"
                sqlcmd -S "$using:computername" -q "exec sp_addsrvrolemember $Account, $Role"
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $Admincreds
            DependsOn = '[SqlLogin]CreateSQLAdminSQLLogin', '[SqlLogin]CreateSQLSvcSQLLogin'
        }

        SqlPermission 'GRANTSYSTEM'
        {
            Ensure               = 'Present'
            ServerName           = "$ComputerName.$DomainName"
            InstanceName         = 'MSSQLSERVER'
            Principal            = 'NT AUTHORITY\SYSTEM'
            Permission           = 'AlterAnyAvailabilityGroup', 'ConnectSql','ViewServerState'
            PsDscRunAsCredential = $Admincreds
            DependsOn = '[Script]GrantSysAdmin'
        }

        SqlServiceAccount 'SetServiceAccount'
        {
            ServerName     = "$ComputerName.$DomainName"
            InstanceName   = 'MSSQLSERVER'
            ServiceType    = 'DatabaseEngine'
            ServiceAccount = $Sqlsvc
            RestartService = $true
        }
    }
}