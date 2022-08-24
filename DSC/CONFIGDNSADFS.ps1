configuration CONFIGDNSADFS
{
   param
   (
        [String]$ExternalDomainName,
        [String]$adfs1IP
    )

    Import-DscResource -ModuleName DnsServerDsc

    Node localhost
    {
        DnsRecordA owa2019record1
        {
            Name      = "adfs"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$adfs1IP"
            Ensure    = 'Present'
        }
    }
}