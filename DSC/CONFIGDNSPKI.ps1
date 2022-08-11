configuration CONFIGDNSPKI
{
   param
   (
        [String]$ExternaldomainName,
        [String]$icaIP,
        [String]$ocspIP
    )

    Import-DscResource -ModuleName DnsServerDsc

    Node localhost
    {
        DnsRecordA crlrecord
        {
            Name      = "crl"
            ZoneName  = "$ExternaldomainName"
            IPv4Address = "$icaIP"
            Ensure    = 'Present'
        }

        DnsRecordA ocsprecord
        {
            Name      = "ocsp"
            ZoneName  = "$ExternaldomainName"
            IPv4Address = "$ocspIP"
            Ensure    = 'Present'
        }
    }
}