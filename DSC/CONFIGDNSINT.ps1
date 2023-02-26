configuration CONFIGDNSINT
{
   param
   (
        [String]$computerName,
        [String]$NetBiosDomain,
        [String]$InternaldomainName,
        [String]$ReverseLookup,
        [String]$ForwardLookup,
        [String]$dclastoctet,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -ModuleName DnsServerDsc

    [System.Management.Automation.PSCredential ]$DomainCredsFQDN = New-Object System.Management.Automation.PSCredential ("$($Admincreds.UserName)@$($InternaldomainName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = "StopConfiguration"
            ConfigurationMode = "ApplyOnly"
        }


$DomainName = 'sub1.killerhomelab.com'
$ComputerName = 'khl-dc-01'
$FQDN = "$ComputerName.$DomainName"
$Forest = Get-ADForest
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
            while (($DomainLoadedEvent -eq $null)){
                Start-Sleep 10
                $DNSLoadedEvent = Get-EventLog -LogName "DNS Server" -ErrorAction 0 | Where-Object {($_.InstanceId -like 4)}
            }
        }
       
        DnsServerADZone ReverseADZone
        {
            Name             = "$ReverseLookup.in-addr.arpa"
            ComputerName = "$computerName.$InternaldomainName"
            DynamicUpdate = 'Secure'
            Ensure           = 'Present'
            ReplicationScope = 'Domain'
            Credential = $DomainCredsFQDN
        }

        DnsRecordPtr DCPtrRecord
        {
            Name      = "$computerName.$InternaldomainName"
            ZoneName = "$ReverseLookup.in-addr.arpa"
            IpAddress = "$ForwardLookup.$dclastoctet"
            DnsServer = "$computerName.$InternaldomainName"
            Ensure    = 'Present'
            DependsOn = "[DnsServerADZone]ReverseADZone"
            PsDscRunAsCredential = $DomainCredsFQDN       
        }
    }
}