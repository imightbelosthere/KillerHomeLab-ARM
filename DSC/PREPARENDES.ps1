﻿configuration PREPARENDES
{
   param
   (
        [String]$computerName,
        [String]$NamingConvention,
        [String]$NetBiosDomain,
        [String]$InternaldomainName,
        [String]$ExternaldomainName,
        [String]$EnterpriseCAName,
        [String]$EnterpriseCAServer,
        [String]$CertificateConnectorEXEURL,
        [String]$Account,
        [System.Management.Automation.PSCredential]$Admincreds   
    )

    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($AdminCreds.UserName)", $AdminCreds.Password)

    Node localhost
    {
        Registry SchUseStrongCrypto
        {
            Key                         = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
            ValueName                   = 'SchUseStrongCrypto'
            ValueType                   = 'Dword'
            ValueData                   =  '1'
            Ensure                      = 'Present'
        }

        Registry SchUseStrongCrypto64
        {
            Key                         = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
            ValueName                   = 'SchUseStrongCrypto'
            ValueType                   = 'Dword'
            ValueData                   =  '1'
            Ensure                      = 'Present'
        }

        File NDESSoftware
        {
            Type = 'Directory'
            DestinationPath = 'C:\NDES-Software'
            Ensure = "Present"
        }

        File WAPCertificates
        {
            Type = 'Directory'
            DestinationPath = 'C:\WAP-Certificates'
            Ensure = "Present"
        }

        #NDES Prereqs
        WindowsFeature ADCS-Device-Enrollment
        {
            Ensure = 'Present'
            Name = 'ADCS-Device-Enrollment'
        }

        WindowsFeature Web-Filtering
        {
            Ensure = 'Present'
            Name = 'Web-Filtering'
        }
        
        WindowsFeature Web-Asp-Net
        {
            Ensure = 'Present'
            Name = 'Web-Asp-Net'
        }

        WindowsFeature Web-Asp-Net45
        {
            Ensure = 'Present'
            Name = 'Web-Asp-Net45'
        }
        
        WindowsFeature  NET-Framework-45-ASPNET
        {
            Ensure = 'Present'
            Name = 'NET-Framework-45-ASPNET'
        }
        
        WindowsFeature NET-WCF-HTTP-Activation45
        {
            Ensure = 'Present'
            Name = 'NET-WCF-HTTP-Activation45'
        }
        
        WindowsFeature Web-Metabase
        {
            Ensure = 'Present'
            Name = 'Web-Metabase'
        }
        
        WindowsFeature Web-WMI
        {
            Ensure = 'Present'
            Name = 'Web-WMI'
        }

        WindowsFeature Web-Mgmt-Console
        {
            Ensure = 'Present'
            Name = 'Web-Mgmt-Console'
        }

        Script GrantIISIUSR
        {
            SetScript =
            {
                $AccountCheck = Get-LocalGroupMember -Group IIS_IUSRS -Member "$using:NetBiosDomain\$using:Account" -ErrorAction 0
                IF ($AccountCheck -eq $null){
                    Add-LocalGroupMember -Member "$using:NetBiosDomain\$using:Account" -Group IIS_IUSRS
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

        Script SetSPN
        {
            SetScript =
            {
                $file = Get-Item -Path "C:\NDES-Software\SETSPN.cmd" -ErrorAction 0
                IF ($file -eq $Null){
                    Set-Content -Path C:\NDES-Software\SETSPN.cmd -Value "c:\windows\system32\setspn.exe -f -s http/$using:computerName.$using:InternalDomainName $using:NetBiosDomain\$using:Account"
                    C:\NDES-Software\SETSPN.cmd
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]GrantIISIUSR'
            PsDscRunAsCredential = $DomainCreds
        }

        Script ConfigureCertificate
        {
            SetScript =
            {
                # Create Credentials
                $Load = "$using:DomainCreds"
                $Password = $DomainCreds.Password

                # Get Certificate 2019 Certificate
                $CertCheck = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=ndes.$using:ExternalDomainName"}
                IF ($CertCheck -eq $Null) {
                    Get-Certificate -Template WebServer1 -SubjectName "CN=ndes.$using:ExternalDomainName" -DNSName "ndes.$using:ExternalDomainName" -CertStoreLocation "cert:\LocalMachine\My"
                }

                $thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=ndes.$using:ExternalDomainName"}).Thumbprint
                (Get-ChildItem -Path Cert:\LocalMachine\My\$thumbprint).FriendlyName = "NDES Certificate"

                # Export NDES Certificate
                $CertFile = Get-ChildItem -Path "C:\WAP-Certificates\ndes.$using:ExternalDomainName.pfx" -ErrorAction 0
                IF ($CertFile -eq $Null) {Get-ChildItem -Path cert:\LocalMachine\my\$thumbprint | Export-PfxCertificate -FilePath "C:\WAP-Certificates\ndes.$using:ExternalDomainName.pfx" -Password $Password}

                # Export Root CA
                $EnterpriseCert = Get-ChildItem -Path "C:\WAP-Certificates\$using:EnterpriseCAName.cer" -ErrorAction 0
                IF ($EnterpriseCert -eq $null)
                {
                    $EnterpriseExport = Get-ChildItem -Path cert:\Localmachine\Root\ | Where-Object {$_.Subject -like "CN=$using:EnterpriseCAName*"}
                    Export-Certificate -Cert $EnterpriseExport -FilePath "C:\WAP-Certificates\$using:EnterpriseCAName.cer" -Type CER
                }

                # Enable Certificate Copy
                $EnableSMB = Get-NetFirewallRule "FPS-SMB-In-TCP" -ErrorAction 0
                IF ($EnableSMB -ne $null) {Enable-NetFirewallRule -Name "FPS-SMB-In-TCP"}
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = "[Script]SetSPN"
        }

        Script ConfigureIIS
        {
            SetScript =
            {
                $BindingCheck = Get-WebBinding -Name "Default Web Site" -Protocol https -ErrorAction 0
                IF ($BindingCheck -eq $Null){
                    $wwwcert = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=ndes.$using:ExternalDomainName"})
                    New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https
                    $Binding = Get-WebBinding -Name "Default Web Site" -Protocol https
                    $Binding.AddSslCertificate($wwwcert.GetCertHashString(), "my")
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $Admincreds
            DependsOn = "[Script]ConfigureCertificate"
        }

        Script ConfigureNDES
        {
            SetScript =
            {
                $Load = "$using:DomainCreds"
                $Password = $Domaincreds.Password

                # $Feature = Get-WindowsFeature | Where-Object {$_.Name -like 'ADCS-Device-Enrollment'}
                # IF ($Feature.Installed -ne 'True'){
                Install-AdcsNetworkDeviceEnrollmentService -ServiceAccountName "$using:NetBiosDomain\$using:Account" -ServiceAccountPassword $Password -CAConfig "$using:EnterpriseCAServer\$using:EnterpriseCAName" -RAName "$using:NamingConvention-NDES-RA" -RACountry 'US' -RACompany "$using:NamingConvention" -SigningProviderName 'Microsoft Strong Cryptographic Provider' -SigningKeyLength 4096 -EncryptionProviderName 'Microsoft Strong Cryptographic Provider' -EncryptionKeyLength 4096 -Credential $DomainCreds -Confirm:$False
                # }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]ConfigureIIS'
        }

        Registry EncryptionTemplate
        {
            Key                         = 'HKLM:\SOFTWARE\Microsoft\Cryptography\MSCEP'
            ValueName                   = 'EncryptionTemplate'
            ValueType                   = 'String'
            ValueData                   =  'SCEPCertificate1'
            Ensure                      = 'Present'
            DependsOn = '[Script]ConfigureNDES'
        }

        Registry SignatureTemplate
        {
            Key                         = 'HKLM:\SOFTWARE\Microsoft\Cryptography\MSCEP'
            ValueName                   = 'SignatureTemplate'
            ValueType                   = 'String'
            ValueData                   =  'SCEPCertificate1'
            Ensure                      = 'Present'
            DependsOn = '[Script]ConfigureNDES'
        }

        Registry GeneralPurposeTemplate
        {
            Key                         = 'HKLM:\SOFTWARE\Microsoft\Cryptography\MSCEP'
            ValueName                   = 'GeneralPurposeTemplate'
            ValueType                   = 'String'
            ValueData                   =  'SCEPCertificate1'
            Ensure                      = 'Present'
            DependsOn = '[Script]ConfigureNDES'
        }

        xRemoteFile DownloadIntuneConnector
        {
            DestinationPath = "C:\NDES-Software\IntuneCertificateConnector.exe"
            Uri             = "$CertificateConnectorEXEURL"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = '[File]NDESSoftware', '[Registry]SchUseStrongCrypto', '[Registry]SchUseStrongCrypto64', '[Registry]EncryptionTemplate', '[Registry]SignatureTemplate', '[Registry]GeneralPurposeTemplate'
        }

        Script InstallIntuneConnector
        {
            SetScript =
            {
                # Install Intune Connector
                $IntuneConnector = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\MicrosoftIntune\PFXCertificateConnector" -Name "AccountId" -ErrorAction 0
                
                IF ($IntuneConnector -eq $null){
                Start-Process "C:\NDES-Software\IntuneCertificateConnector.exe" -ArgumentList "/install /quiet" -Wait
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]DownloadIntuneConnector'
        }

    }
}