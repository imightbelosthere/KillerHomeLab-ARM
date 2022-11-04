configuration CREATESQLLOGIN
{
   param
   (
        [String]$computerName,
        [String]$InstallAccount,
        [String]$SvcAccount,        
        [String]$NetBiosDomain,
        [String]$DomainName,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    [System.Management.Automation.PSCredential ]$Sqlsvc = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$SvcAccount", $Admincreds.Password)

    Import-DscResource -Module SqlServerDsc # Used for SQL Configurations

    Node localhost
    {
        SqlLogin CreateInstallSQLLogin
        {
            Ensure               = 'Present'
            Name                 = "$NetBiosDomain\$InstallAccount"
            LoginType            = 'WindowsUser'
            ServerName           = "$ComputerName.$DomainName"
            InstanceName         = 'MSSQLSERVER'
            PsDscRunAsCredential = $Admincreds
        }

        SqlLogin CreateSQLSvcSQLLogin
        {
            Ensure               = 'Present'
            Name                 = "$NetBiosDomain\$SvcAccount"
            LoginType            = 'WindowsUser'
            ServerName           = "$ComputerName.$DomainName"
            InstanceName         = 'MSSQLSERVER'
            PsDscRunAsCredential = $Admincreds
        }

        Script GrantSysAdmin
        {
            SetScript =
            {
                $RawAccount = "$using:NetBiosDomain\$using:InstallAccount"
                $Account = "'"+$RawAccount+"'"
                $Role = "'sysadmin'"
                sqlcmd -S "$using:computername" -q "exec sp_addsrvrolemember $Account, $Role"
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $Admincreds
            DependsOn = '[SqlLogin]CreateInstallSQLLogin', '[SqlLogin]CreateSQLSvcSQLLogin'
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