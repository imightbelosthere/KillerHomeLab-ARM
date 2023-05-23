configuration OTHERDC
{
   param
    (
        [String]$InternaldomainName,
        [System.Management.Automation.PSCredential]$Admincreds,
        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xStorage # used for xDisk
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName ComputerManagementDsc # Used for Reboots
    Import-DscResource -ModuleName DNSServerDsc

    [System.Management.Automation.PSCredential ]$DomainCredsFQDN = New-Object System.Management.Automation.PSCredential ("$($Admincreds.UserName)@$($InternaldomainName)", $Admincreds.Password)

    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)

    Node localhost
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = "StopConfiguration"
            ConfigurationMode = "ApplyOnly"
        }

        Script EnableTls12
        {
            SetScript =
            {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

        WaitForADDomain LocateDomain
        {
            DomainName = $InternaldomainName
            WaitTimeout = 600
            RestartCount = 2
            DependsOn = '[Script]EnableTls12'
        }

        WindowsFeature DNS
        {
            Ensure = "Present"
            Name = "DNS"
            DependsOn = '[WaitForADDomain]LocateDomain'
        }

        Script EnableDNSDiags
        {
      	    SetScript = {
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics"
            }
            GetScript =  { @{} }
            TestScript = { $false }
            DependsOn = "[WindowsFeature]DNS"
        }

        WindowsFeature DnsTools
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }

        xWaitforDisk Disk2
        {
                DiskId = 2
                RetryIntervalSec =$RetryIntervalSec
                RetryCount = $RetryCount
        }

        xDisk ADDataDisk
        {
            DiskId = 2
            DriveLetter = "N"
            DependsOn = "[xWaitForDisk]Disk2"
        }

        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }

        WindowsFeature 'RSATADPowerShell'
        {
            Ensure    = 'Present'
            Name      = 'RSAT-AD-PowerShell'

            DependsOn = '[WindowsFeature]ADDSInstall'
        }

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = '[WindowsFeature]ADDSInstall'
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSTools"
        }

        ADDomainController OtherDS
        {
            DomainName = $InternaldomainName
            Credential = $DomainCredsFQDN
            SafemodeAdministratorPassword = $DomainCredsFQDN
            DatabasePath = "N:\NTDS"
            LogPath = "N:\NTDS"
            SysvolPath = "N:\SYSVOL"
            DependsOn = '[WindowsFeature]ADAdminCenter'
        }

        Script UpdateDNSSettings
        {
            SetScript =
            {
                # Reset DNS
                Set-DnsClientServerAddress -InterfaceAlias "$using:InterfaceAlias" -ResetServerAddresses
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[ADDomainController]OtherDS'
        }
    }
}









    