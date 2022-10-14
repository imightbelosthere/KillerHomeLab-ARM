configuration CONFIGDNSAKS
{
   param
   (
        [String]$DNSIP,                                       
        [String]$AKSDNSZone
    )

    Import-DscResource -ModuleName DnsServerDsc

    Node localhost
    {
        DnsServerConditionalForwarder AKSDnsZone
        {
            Name      = $AKSDNSZone
            MasterServers = $DNSIP
            Ensure    = 'Present'
        }
    }
}