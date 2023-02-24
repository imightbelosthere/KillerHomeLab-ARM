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