configuration CONFIGDNSEXT
{
   param
   (
        [String]$computerName,
        [String]$InternaldomainName,
        [String]$ExternaldomainName,
        [String]$ReverseLookup,
        [String]$ForwardLookup,
        [String]$dclastoctet,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -ModuleName DnsServerDsc
    Import-DscResource -ModuleName ActiveDirectoryDsc

    [System.Management.Automation.PSCredential ]$DomainCredsFQDN = New-Object System.Management.Automation.PSCredential ("$($Admincreds.UserName)@$($InternaldomainName)", $Admincreds.Password)

    Node localhost
    {
        DnsServerADZone ExternalDomain
        {
            Name             = "$ExternaldomainName"
            DynamicUpdate = 'Secure'
            Ensure           = 'Present'
            ReplicationScope = 'Domain'
        }

        Script CheckDNS
        {
            SetScript =
            {

                $Server = Get-ComputerInfo
                $ServerName = $Server.CsDNSHostName
                $DomainName = $Server.CsDomain
                $FQDN = $ServerName + '.' + $DomainName

                $Service = Get-Service -Name NTDS
                while (($Service.Status -ne 'Running')){
                    Start-Sleep 10
                    $Service = Get-Service -Name NTDS
                }

                $Forest = Get-ADForest -ErrorAction 0
                while (($Forest -eq $null)){
                    Start-Sleep 10
                    $Forest = Get-ADForest -ErrorAction 0
                }
                $SchemaMaster = $Forest.SchemaMaster

                IF ($FQDN -eq $SchemaMaster){
                    $DomainEvent = Get-EventLog -LogName "DNS Server" -ErrorAction 0 | Where-Object {($_.InstanceId -like 4500) -and ($_.Message -like '*Domain*')}
                    while (($DomainEvent -eq $null)){
                        Start-Sleep 10
                        $DomainEvent = Get-EventLog -LogName "DNS Server" -ErrorAction 0 | Where-Object {($_.InstanceId -like 4500) -and ($_.Message -like '*Domain*')}
                    }

                    $ForestEvent = Get-EventLog -LogName "DNS Server" -ErrorAction 0 | Where-Object {($_.InstanceId -like 4500) -and ($_.Message -like '*Forest*')}
                    while (($ForestEvent -eq $null)){
                        Start-Sleep 10
                        $ForestEvent = Get-EventLog -LogName "DNS Server" -ErrorAction 0 | Where-Object {($_.InstanceId -like 4500) -and ($_.Message -like '*Forest*')}
                    }
                }

                ELSE {
                    $DNSLoadedEvent = Get-EventLog -LogName "DNS Server" -ErrorAction 0 | Where-Object {($_.InstanceId -like 4)}
                    while (($DNSLoadedEvent -eq $null)){
                        Start-Sleep 10
                        $DNSLoadedEvent = Get-EventLog -LogName "DNS Server" -ErrorAction 0 | Where-Object {($_.InstanceId -like 4)}
                    }
                }

            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

        WaitForADDomain Domain
        {
            DomainName           = $InternaldomainName
            WaitTimeout          = 600
            RestartCount         = 2
            Credential = $DomainCredsFQDN
            DependsOn = '[Script]CheckDNS'
        }

        DnsServerADZone ReverseADZone1
        {
            Name             = "$ReverseLookup.in-addr.arpa"
            DynamicUpdate = 'Secure'
            Ensure           = 'Present'
            ReplicationScope = 'Domain'
            DependsOn = '[WaitForADDomain]Domain'
        }

        DnsRecordPtr DC1PtrRecord
        {
            Name      = "$computerName.$InternaldomainName"
            ZoneName = "$ReverseLookup.in-addr.arpa"
            IpAddress = "$ForwardLookup.$dclastoctet"
            Ensure    = 'Present'
            DependsOn = "[DnsServerADZone]ReverseADZone1"           
        }
    }
}