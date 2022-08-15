Configuration ENTERPRISECA
{
   param
   (
        [String]$NetBiosDomain,
        [String]$domainName,
        [String]$EnterpriseCAHashAlgorithm,
        [String]$EnterpriseCAKeyLength,
        [String]$EnterpriseCAName,
        [String]$CATemplateScriptUrl,
        [System.Management.Automation.PSCredential]$Admincreds
    )
 
    Import-DscResource -Module ActiveDirectoryCSDsc
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

        WindowsFeature ADCSCA 
        {
            Name = 'ADCS-Cert-Authority'
            Ensure = 'Present'
        }

        WindowsFeature WebEnrollmentCA
        {
            Name = 'ADCS-Web-Enrollment'
            Ensure = 'Present'
        }

        WindowsFeature RSAT-ADCS 
        { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS' 
        } 

        WindowsFeature Web-Mgmt-Console
        { 
            Ensure = 'Present' 
            Name = 'Web-Mgmt-Console' 
        }

        WindowsFeature RSAT-ADCS-Mgmt 
        { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS-Mgmt' 
        }

        File CertEnroll
        {
            Type = 'Directory'
            DestinationPath = 'C:\CertEnroll'
            Ensure = "Present"
        }

        ADCSCertificationAuthority CertificateAuthority
        {
            Ensure = 'Present'
	        Credential = $DomainCreds
            CAType = 'EnterpriseRootCA'
            CACommonName = $EnterpriseCAName
            CADistinguishedNameSuffix = $Node.CADistinguishedNameSuffix
            ValidityPeriod = 'Years'
            ValidityPeriodUnits = 20
            CryptoProviderName = 'RSA#Microsoft Software Key Storage Provider'
            HashAlgorithmName = $EnterpriseCAHashAlgorithm
            KeyLength = $EnterpriseCAKeyLength
            IsSingleInstance = 'Yes'
            DependsOn = '[WindowsFeature]ADCSCA','[WindowsFeature]WebEnrollmentCA'
        }

        ADCSWebEnrollment ConfigWebEnrollment
        {
            Ensure = 'Present'
            Credential = $DomainCreds
            IsSingleInstance = 'Yes'
            DependsOn = '[WindowsFeature]ADCSCA','[WindowsFeature]WebEnrollmentCA','[AdcsCertificationAuthority]CertificateAuthority'
        }

        File CopyEnterpriseCACRl
        {
            Ensure = "Present"
            Type = "File"
            SourcePath = "C:\Windows\System32\certsrv\CertEnroll\$EnterpriseCAName.crl"
            DestinationPath = "C:\CertEnroll\$EnterpriseCAName.crl"
            Credential = $DomainCreds
            DependsOn = '[File]CertEnroll', '[AdcsCertificationAuthority]CertificateAuthority'
        }

        xRemoteFile DownloadCreateCATemplates
        {
            DestinationPath = "C:\CertEnroll\Create_CA_Templates.ps1"
            Uri             = $CATemplateScriptUrl
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
        }

        Script ConfigureEnterpriseCA
        {
            SetScript =
            {
                C:\Windows\system32\inetsrv\appcmd.exe set config /section:requestfiltering /allowdoubleescaping:true

                # Remove All Default CDP Locations
                Get-CACrlDistributionPoint | Where-Object {$_.Uri -like 'ldap*'} | Remove-CACrlDistributionPoint -Force
                Get-CACrlDistributionPoint | Where-Object {$_.Uri -like 'http*'} | Remove-CACrlDistributionPoint -Force
                Get-CACrlDistributionPoint | Where-Object {$_.Uri -like 'file*'} | Remove-CACrlDistributionPoint -Force

                # Check for and if not present add LDAP CDP Location
                $LDAPCDPURI = Get-CACrlDistributionPoint | Where-object {$_.uri -like "ldap:///CN=<CATruncatedName><CRLNameSuffix>"+"*"}
                IF ($LDAPCDPURI.uri -eq $null){Add-CACRLDistributionPoint -Uri "ldap:///CN=<CATruncatedName><CRLNameSuffix>,CN=<ServerShortName>,CN=CDP,CN=Public Key Services,CN=Services,<ConfigurationContainer><CDPObjectClass>" -PublishToServer -AddToCertificateCDP -AddToCrlCdp -Force}

                # Check for and if not present add HTTP CDP Location
                $HTTPCDPURI = Get-CACrlDistributionPoint | Where-object {$_.uri -like "http://crl"+"*"}
                IF ($HTTPCDPURI.uri -eq $null){Add-CACRLDistributionPoint -Uri "http://crl.$using:domainName/CertEnroll/<CAName><CRLNameSuffix><DeltaCRLAllowed>.crl" -AddToCertificateCDP -AddToFreshestCrl -Force}

                # Remove All Default AIA Locations
                Get-CAAuthorityInformationAccess | Where-Object {$_.Uri -like 'ldap*'} | Remove-CAAuthorityInformationAccess -Force
                Get-CAAuthorityInformationAccess | Where-Object {$_.Uri -like 'http*'} | Remove-CAAuthorityInformationAccess -Force
                Get-CAAuthorityInformationAccess | Where-Object {$_.Uri -like 'file*'} | Remove-CAAuthorityInformationAccess -Force

                # Check for and if not present add LDAP AIA Location
                $LDAPAIAURI = Get-CAAuthorityInformationaccess | Where-object {$_.uri -like "ldap:///CN=<CATruncatedName>,CN=AIA"+"*"}
                IF ($LDAPAIAURI.uri -eq $null){Add-CAAuthorityInformationaccess -Uri "ldap:///CN=<CATruncatedName>,CN=AIA,CN=Public Key Services,CN=Services,<ConfigurationContainer><CAObjectClass>" -AddToCertificateAia -Force}

                # Check for and if not present add HTTP AIA Location
                $HTTPAIAURI = Get-CAAuthorityInformationaccess | Where-object {$_.uri -like "http://crl"+"*"}
                IF ($HTTPAIAURI.uri -eq $null){Add-CAAuthorityInformationaccess -Uri "http://ocsp.$using:DomainName/ocsp" -AddToCertificateOcsp -Force}
                Restart-Service -Name CertSvc 
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[File]CopyEnterpriseCACRl'
        }

        Script CreateCATemplates
        {
            SetScript =
            {
                $Load = "$using:DomainCreds"
                $Domain = $DomainCreds.GetNetworkCredential().Domain
                $Username = $DomainCreds.GetNetworkCredential().UserName
                $Password = $DomainCreds.GetNetworkCredential().Password 

                # Create CA Templates
                $scheduledtask = Get-ScheduledTask "Create CA Templates" -ErrorAction 0
                $action = New-ScheduledTaskAction -Execute Powershell -Argument '.\Create_CA_Templates.ps1' -WorkingDirectory 'C:\CertEnroll'
                IF ($scheduledtask -eq $null) {
                Register-ScheduledTask -Action $action -TaskName "Create CA Templates" -Description "Create Web Server & OCSP CA Templates" -User $Domain\$Username -Password $Password
                Start-ScheduledTask "Create CA Templates"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]DownloadCreateCATemplates', '[Script]ConfigureEnterpriseCA'
        }
   
     }
  }