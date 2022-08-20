configuration CONFIGDNSEX19
{
   param
   (
        [String]$ExternaldomainName,
        [String]$ex1IP
    )

    Import-DscResource -ModuleName DnsServerDsc

    Node localhost
    {
        DnsRecordA owa2019record1
        {
            Name      = "owa2019"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$ex1IP"
            Ensure    = 'Present'
        }

        DnsRecordA autodiscover2019record1
        {
            Name      = "autodiscover2019"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$ex1IP"
            Ensure    = 'Present'
        }

        DnsRecordA outlook2019record1
        {
            Name      = "outlook2019"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$ex1IP"
            Ensure    = 'Present'
        }

        DnsRecordA eas2019record1
        {
            Name      = "eas2019"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$ex1IP"
            Ensure    = 'Present'
        }

        DnsRecordA smtprecord1
        {
            Name      = "smtp"
            ZoneName  = "$ExternaldomainName"
            IPv4Address = "$ex1IP"
            Ensure    = 'Present'
         }
    }
}