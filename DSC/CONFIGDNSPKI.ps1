configuration CONFIGDNSPKI
{
   param
   (
        [String]$ExternaldomainName,
        [String]$crlIP,
        [String]$ocspIP
    )

    Import-DscResource -ModuleName DnsServerDsc

    Node localhost
    {
        DnsRecordA crlrecord
        {
            Name      = "crl"
            ZoneName  = "$ExternaldomainName"
            IPv4Address = "$crlIP"
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