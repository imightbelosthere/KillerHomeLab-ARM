configuration DOMAINCONTROLLER
{
   param
   (      
        [String]$InternaldomainName,
        [String]$PrimaryDC,
        [System.Management.Automation.PSCredential]$Admincreds,
        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName xStorage
    Import-DscResource -ModuleName xNetworking

    [System.Management.Automation.PSCredential ]$DomainCredsFQDN = New-Object System.Management.Automation.PSCredential ("$($Admincreds.UserName)@$($InternaldomainName)", $Admincreds.Password)
    $Interface=Get-NetAdapter|Where-Object Name -Like "Ethernet*"|Select-Object -First 1
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

        if ($PrimaryDC -eq "Yes")
        {
            WindowsFeature DNS
            {
                Ensure = "Present"
                Name = "DNS"
                DependsOn = '[Script]EnableTls12'
            }

            WindowsFeature DnsTools
            {
                Ensure = "Present"
                Name = "RSAT-DNS-Server"
                DependsOn = "[WindowsFeature]DNS"
            }

            WindowsFeature ADDSInstall
            {
                Ensure = "Present"
                Name = "AD-Domain-Services"
                DependsOn="[WindowsFeature]DnsTools"
            }

            WindowsFeature RSATADPowerShell
            {
                Ensure    = 'Present'
                Name      = 'RSAT-AD-PowerShell'
                DependsOn = '[WindowsFeature]ADDSInstall'
            }

            WindowsFeature ADDSTools
            {
                Ensure = "Present"
                Name = "RSAT-ADDS-Tools"
                DependsOn = "[WindowsFeature]RSATADPowerShell"
            }

            WindowsFeature ADAdminCenter
            {
                Ensure = "Present"
                Name = "RSAT-AD-AdminCenter"
                DependsOn = "[WindowsFeature]ADDSTools"
            }

            xWaitforDisk Disk2
            {
                DiskID = 2
                RetryIntervalSec =$RetryIntervalSec
                RetryCount = $RetryCount
            }

            xDisk ADDataDisk {
                DiskID = 2
                DriveLetter = "N"
                DependsOn = "[xWaitForDisk]Disk2"
            }

            Script EnableDNSDiags
            {
                SetScript = {
                    Set-DnsServerDiagnostics -All $true
                    Write-Verbose -Verbose "Enabling DNS client diagnostics"
                }
                GetScript =  { @{} }
                TestScript = { $false }
                DependsOn = '[xDisk]ADDataDisk'
            }

            ADDomain FirstDC
            {
                DomainName = $InternaldomainName
                Credential = $DomainCredsFQDN
                SafemodeAdministratorPassword = $DomainCredsFQDN
                DatabasePath = "N:\NTDS"
                LogPath = "N:\NTDS"
                SysvolPath = "N:\SYSVOL"
                DependsOn = '[Script]EnableDNSDiags'
            }

            xDnsServerAddress DnsServerAddress
            {
                Address        = '127.0.0.1'
                InterfaceAlias = $InterfaceAlias
                AddressFamily  = 'IPv4'
                DependsOn = "[ADDomain]FirstDC"
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
                DependsOn = "[xDnsServerAddress]DnsServerAddress"
            }
        }

        else
        {
            WaitForADDomain Domain
            {
                DomainName           = $InternaldomainName
                WaitTimeout          = 600
                RestartCount         = 2
                Credential = $DomainCredsFQDN
                DependsOn = '[Script]EnableTls12'
            }

            WindowsFeature DNS
            {
                Ensure = "Present"
                Name = "DNS"
                DependsOn = '[Script]EnableTls12'
            }

            WindowsFeature DnsTools
            {
                Ensure = "Present"
                Name = "RSAT-DNS-Server"
                DependsOn = "[WindowsFeature]DNS"
            }

            WindowsFeature ADDSInstall
            {
                Ensure = "Present"
                Name = "AD-Domain-Services"
                DependsOn="[WindowsFeature]DnsTools"
            }

            WindowsFeature RSATADPowerShell
            {
                Ensure    = 'Present'
                Name      = 'RSAT-AD-PowerShell'
                DependsOn = '[WindowsFeature]ADDSInstall'
            }

            WindowsFeature ADDSTools
            {
                Ensure = "Present"
                Name = "RSAT-ADDS-Tools"
                DependsOn = "[WindowsFeature]RSATADPowerShell"
            }

            WindowsFeature ADAdminCenter
            {
                Ensure = "Present"
                Name = "RSAT-AD-AdminCenter"
                DependsOn = "[WindowsFeature]ADDSTools"
            }

            xWaitforDisk Disk2
            {
                DiskID = 2
                RetryIntervalSec =$RetryIntervalSec
                RetryCount = $RetryCount
            }

            xDisk ADDataDisk {
                DiskID = 2
                DriveLetter = "N"
                DependsOn = "[xWaitForDisk]Disk2"
            }

            Script EnableDNSDiags
            {
                SetScript = {
                    Set-DnsServerDiagnostics -All $true
                    Write-Verbose -Verbose "Enabling DNS client diagnostics"
                }
                GetScript =  { @{} }
                TestScript = { $false }
                DependsOn = '[xDisk]ADDataDisk'
            }

            ADDomainController OtherDC
            {
                DomainName = $InternaldomainName
                Credential = $DomainCredsFQDN
                SafemodeAdministratorPassword = $DomainCredsFQDN
                DatabasePath = "N:\NTDS"
                LogPath = "N:\NTDS"
                SysvolPath = "N:\SYSVOL"
                DependsOn = '[Script]EnableDNSDiags'
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
                DependsOn = '[ADDomainController]OtherDC'
            }
        }
    }
}