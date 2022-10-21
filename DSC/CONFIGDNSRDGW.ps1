configuration CONFIGDNSRDGW
{
   param
   (
        [String]$ExternaldomainName,
        [String]$rdgwIP
    )

    Import-DscResource -ModuleName DnsServerDsc

    Node localhost
    {
        DnsServerADZone ExternalDomain
        {
            Name             = "$ExternaldomainName"
            DynamicUpdate = 'Secure'
            Ensure           = 'Present'
            ReplicationScope = 'Domain'
        }

        DnsRecordA rdgwrecord
        {
            Name      = "rdgw"
            ZoneName  = "$ExternaldomainName"
            IPv4Address = "$rdgwIP"
            Ensure    = 'Present'
            DependsOn = '[DnsServerADZone]ExternalDomain'
        }
    }
}