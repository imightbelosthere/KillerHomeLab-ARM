configuration CONFIGDNSINT
{
   param
   (
        [String]$computerName,
        [String]$NetBiosDomain,
        [String]$InternaldomainName,
        [String]$ReverseLookup,
        [String]$ForwardLookup,
        [String]$dclastoctet,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -ModuleName DnsServerDsc

    [System.Management.Automation.PSCredential ]$DomainCredsFQDN = New-Object System.Management.Automation.PSCredential ("$($Admincreds.UserName)@$($InternaldomainName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = "StopConfiguration"
            ConfigurationMode = "ApplyOnly"
        }

        $DNSService = Get-Service -Name DNS
        while (($DNSService.Status -ne 'Running')){
            Start-Sleep 10
            $DNSService = Get-Service -Name DNS
        }

        $DNScacheService = Get-Service -Name DNScache
        while (($DNScacheService.Status -ne 'Running')){
            Start-Sleep 10
            $DNScacheService = Get-Service -Name DNS
        }
       
        DnsServerADZone ReverseADZone
        {
            Name             = "$ReverseLookup.in-addr.arpa"
            ComputerName = "$computerName.$InternaldomainName"
            DynamicUpdate = 'Secure'
            Ensure           = 'Present'
            ReplicationScope = 'Domain'
            Credential = $DomainCredsFQDN
        }

        DnsRecordPtr DCPtrRecord
        {
            Name      = "$computerName.$InternaldomainName"
            ZoneName = "$ReverseLookup.in-addr.arpa"
            IpAddress = "$ForwardLookup.$dclastoctet"
            DnsServer = "$computerName.$InternaldomainName"
            Ensure    = 'Present'
            DependsOn = "[DnsServerADZone]ReverseADZone"
            PsDscRunAsCredential = $DomainCredsFQDN       
        }
    }
}