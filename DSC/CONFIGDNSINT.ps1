configuration CONFIGDNSINT
{
   param
   (
        [String]$computerName,
        [String]$NetBiosDomain,
        [String]$InternaldomainName,
        [String]$ReverseLookup,
        [String]$ForwardLookup,
        [String]$dclastoctet
    )

    Import-DscResource -ModuleName DnsServerDsc

    Node localhost
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = "StopConfiguration"
            ConfigurationMode = "ApplyOnly"
        }

        $DNSService = Get-Service -Name DNS
        while (($Service.Status -ne 'Running')){
            Start-Sleep 10
            $DNSService = Get-Service -Name DNS
        }

        $DNScacheService = Get-Service -Name DNScache
        while (($Service.Status -ne 'Running')){
            Start-Sleep 10
            $DNScacheService = Get-Service -Name DNS
        }
       
        DnsServerADZone ReverseADZone
        {
            Name             = "$ReverseLookup.in-addr.arpa"
            DynamicUpdate = 'Secure'
            Ensure           = 'Present'
            ReplicationScope = 'Domain'
        }

        DnsRecordPtr DCPtrRecord
        {
            Name      = "$computerName.$InternaldomainName"
            ZoneName = "$ReverseLookup.in-addr.arpa"
            IpAddress = "$ForwardLookup.$dclastoctet"
            Ensure    = 'Present'
            DependsOn = "[DnsServerADZone]ReverseADZone"           
        }
    }
}