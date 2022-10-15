configuration CONFIGDNSPROXY
{
   param
   (
        [String]$computerName,
        [String]$computerIP,
        [String]$AKSDNSZone,                               
        [String]$InternalDomainName,
        [String]$DC1IP,                                       
        [String]$DNSProxyLocalDomain,                               
        [String]$ReverseLookup,
        [String]$dnslastoctet
    )

    Import-DscResource -ModuleName DnsServerDsc

    Node localhost
    {
        Script SetPrimaryDNSSuffix
        {
            SetScript =
            {
                $domain = get-itemproperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\ -Name "Domain" -ErrorAction 0
                $nvdomain = get-itemproperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\ -Name "NV Domain" -ErrorAction 0

                IF ($domain -eq $null) {Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\" -Name Domain -Value "$using:LocalDNSDomain"}
                IF ($nvdomain -eq $null) {Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\" -Name "NV Domain" -Value "$using:LocalDNSDomain"}
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

        WindowsFeature DNS
        {
            Ensure = "Present"
            Name = "DNS"
        }

        WindowsFeature DnsTools
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }

        DnsServerPrimaryZone DNSLOCAL
        {
            Name             = $DNSProxyLocalDomain
            Ensure           = 'Present'
            DependsOn = '[WindowsFeature]DNS', '[WindowsFeature]DnsTools'
        }

        DnsRecordA DNSPROXY
        {
            Name      = "$computerName"
            ZoneName  = "$DNSProxyLocalDomain"
            IPv4Address  = "$computerIP"
            Ensure    = 'Present'
            DependsOn = '[DnsServerPrimaryZone]DNSLOCAL'
        }

        DnsServerPrimaryZone ReverseLookupZone
        {
            Name             = "$ReverseLookup.in-addr.arpa"
            Ensure           = 'Present'
            DependsOn = '[WindowsFeature]DNS', '[WindowsFeature]DnsTools'
        }

        Script CreatePointerRecord
        {
            SetScript =
            {
                $ZoneName = "$using:ReverseLookup.in-addr.arpa"
                $PtrExists = Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType "PTR" -Name "$using:dnslastoctet" -ErrorAction 0
    
                if ($PtrExists -eq $null)
                {
                    Add-DnsServerResourceRecord -Name "$using:dnslastoctet" -Ptr -ZoneName $ZoneName -AllowUpdateAny -PtrDomainName "$using:computerName.$using:LocalDNSDomain"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[DnsServerPrimaryZone]ReverseLookupZone'
        }

        DnsServerConditionalForwarder AKSDnsZone
        {
            Name      = $AKSDNSZone
            MasterServers = "168.63.129.16"
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]DNS', '[WindowsFeature]DnsTools'
        }

        DnsServerConditionalForwarder InternalDomainName
        {
            Name      = $InternalDomainName
            MasterServers = $DC1IP
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]DNS', '[WindowsFeature]DnsTools'
        }
    }
}