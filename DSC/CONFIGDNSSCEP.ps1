configuration CONFIGDNSSCEP
{
   param
   (
        [String]$ExternaldomainName,
        [String]$ndesIP
    )

    Import-DscResource -ModuleName DnsServerDsc

    Node localhost
    {
        DnsRecordA ocsprecord
        {
            Name      = "ndes"
            ZoneName  = "$ExternaldomainName"
            IPv4Address = "$ndesIP"
            Ensure    = 'Present'
        }
    }
}