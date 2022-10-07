Configuration WAPINTUNE
{
   param
   (
        [String]$NDESServerIP,
        [String]$ExternalDomainName,
        [String]$EnterpriseCAName,
        [System.Management.Automation.PSCredential]$Admincreds
 
    )
 
    Node localhost
    {
        Script AllowRemoteCopy
        {
            SetScript =
            {
                # Allow Remote Copy
                $winrmserviceitem = get-item -Path "HKLM:\Software\Policies\Microsoft\Windows\WinRm\Service" -ErrorAction 0
                $allowunencrypt = get-itemproperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WinRm\Service" -Name "AllowUnencryptedTraffic" -ErrorAction 0
                $allowbasic = get-itemproperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WinRm\Service" -Name "AllowBasic" -ErrorAction 0
                $firewall = Get-NetFirewallRule "FPS-SMB-In-TCP" -ErrorAction 0
                IF ($winrmserviceitem -eq $null) {New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\WinRm\" -Name "Service" -Force}
                IF ($allowunencrypt -eq $null) {New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service\" -Name "AllowUnencryptedTraffic" -Value 1}
                IF ($allowbasic -eq $null) {New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service\" -Name "AllowBasic" -Value 1}
                IF ($firewall -ne $null) {Enable-NetFirewallRule -Name "FPS-SMB-In-TCP"}
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

        File CopyServiceCommunicationCertFromNDES
        {
            Ensure = "Present"
            Type = "Directory"
            Recurse = $true
            SourcePath = "\\$NDESServerIP\c$\WAP-Certificates"
            DestinationPath = "C:\WAP-Certificates\"
            Credential = $Admincreds
            DependsOn = '[Script]AllowRemoteCopy'
        }

        # Install Web Application Proxy
        WindowsFeature Web-Application-Proxy
        {
            Name = 'Web-Application-Proxy'
            Ensure = 'Present'
        }

        WindowsFeature RSAT-RemoteAccess 
        { 
            Ensure = 'Present'
            Name = 'RSAT-RemoteAccess'
        }

        Script ConfigureWAPCertificates
        {
            SetScript =
            {
                # Create Credentials
                $LoadCreds = "$using:AdminCreds"
                $Password = $AdminCreds.Password

                # Add Host Record for Resolution
                Add-Content C:\Windows\System32\Drivers\Etc\Hosts "$using:NDESServerIP ndes.$using:ExternalDomainName"

                #Check if NDES Service Communication Certificate already exists if NOT Create
                $ndesthumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like 'CN=ndes.*'}).Thumbprint
                IF ($ndesthumbprint -eq $null) {Import-PfxCertificate -FilePath "C:\WAP-Certificates\ndes.$using:ExternalDomainName.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $Password}

                #Check if Certificate Chain Certs already exists if NOT Create
                $importenterpriseca = (Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {$_.Subject -like "CN=$using:EnterpriseCAName*"}).Thumbprint
                IF ($importenterpriseca -eq $null) {Import-Certificate -FilePath "C:\WAP-Certificates\$using:EnterpriseCAName.cer" -CertStoreLocation Cert:\LocalMachine\Root}
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[File]CopyServiceCommunicationCertFromNDES'
        }

        Script ConfigureWAP
        {
            SetScript =
            {
                # Disable TLS 1.3
                $OS = (Get-WMIObject win32_operatingsystem).name
                IF ($OS -like '*2022*'){
                    $TLS13Key = get-item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client" -ErrorAction 0
                    IF ($TLS13Key -eq $null) {New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\" -Name "Client" -Force}
                    $DisabledByDefault = get-itemproperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client" -Name "DisabledByDefault" -ErrorAction 0
                    IF ($DisabledByDefault -eq $null) {New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client\" -Name "DisabledByDefault" -Value 1}
                    $Enabled = get-itemproperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client" -Name "Enabled" -ErrorAction 0
                    IF ($Enabled -eq $null) {New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client\" -Name "Enabled" -Value 0}
                }

                # Create NDES Publishing Rule
                $ndesthumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=ndes.$using:ExternalDomainName"}).Thumbprint

                $NDESWPR = Get-WebApplicationProxyApplication | Where-Object {$_.Name -like "NDES Server"} -ErrorAction 0
                IF ($NDESWPR -eq $Null){
                    Add-WebApplicationProxyApplication -BackendServerUrl "https://ndes.$ExternalDomainName/certsrv/mscep/" -ExternalCertificateThumbprint $ndesthumbprint -ExternalUrl "https://ndes.$ExternalDomainName/certsrv/mscep/" -Name "NDES Server" -ExternalPreAuthentication "PassThrough"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]ConfigureWAPCertificates'
        }
    }
  }