Configuration ENTERPRISECA
{
   param
   (
        [String]$NetBiosDomain,
        [String]$domainName,
        [String]$EnterpriseCAHashAlgorithm,
        [String]$EnterpriseCAKeyLength,
        [String]$EnterpriseCAName,
        [System.Management.Automation.PSCredential]$Admincreds
    )
 
    Import-DscResource -Module ActiveDirectoryCSDsc

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($AdminCreds.UserName)", $AdminCreds.Password)
 
    Node localhost
    {
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

                $msPKIRAApplicationPolicies = '"msPKI-RA-Application-Policies"'
                $msPKIAsymmetric = "'"+'msPKI-Asymmetric-Algorithm`PZPWSTR`RSA`msPKI-Hash-Algorithm`PZPWSTR`SHA256`'+"'"
                $msPKI = '$NewOCSPTempl'+".put($msPKIRAApplicationPolicies, $msPKIAsymmetric)"

                # Create CA Template Script
                Set-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '# Set AD Context'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '# Create Web Server Certificate Template'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl = $ADSI.Create("pKICertificateTemplate", "CN=WebServer1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("distinguishedName","CN=WebServer1,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("flags","131680")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("displayName","Web Server1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("revision","100")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("pKIDefaultKeySpec","1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.SetInfo()'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("pKIMaxIssuingDepth","0")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("pKICriticalExtensions","2.5.29.15")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("pKIExtendedKeyUsage","1.3.6.1.5.5.7.3.1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("pKIDefaultCSPs","1,Microsoft RSA SChannel Cryptographic Provider")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("msPKI-RA-Signature","0")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("msPKI-Enrollment-Flag","8")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("msPKI-Private-Key-Flag","16842768")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("msPKI-Certificate-Name-Flag","1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("msPKI-Minimal-Key-Size","2048")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("msPKI-Template-Schema-Version","2")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("msPKI-Template-Minor-Revision","2")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.7183632.6046387.16009101.13536898.4471759.164.5869043.12046343")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.put("msPKI-Certificate-Application-Policy","1.3.6.1.5.5.7.3.1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.SetInfo()'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$BaseWebTempl = $ADSI.psbase.children | where {$_.displayName -eq "Web Server"}'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.pKIKeyUsage = $BaseWebTempl.pKIKeyUsage'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.pKIExpirationPeriod = $BaseWebTempl.pKIExpirationPeriod'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.pKIOverlapPeriod = $BaseWebTempl.pKIOverlapPeriod'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.SetInfo()'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl | select *'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$acl = $NewWebTempl.psbase.ObjectSecurity'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$acl | select -ExpandProperty Access'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$AdObj = New-Object System.Security.Principal.NTAccount("Authenticated Users")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$identity = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$adRights = "ReadProperty, ExtendedRight, GenericExecute"'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$type = "Allow"'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity,$adRights,$type)'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.psbase.ObjectSecurity.SetAccessRule($ACE)'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewWebTempl.psbase.commitchanges()'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '# Create OCSP Certificate Template'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl = $ADSI.Create("pKICertificateTemplate", "CN=OCSPResponseSigning1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("distinguishedName","CN=OCSPResponseSigning1,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("flags","66112")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("displayName","OCSP Response Signing1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("revision","100")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("pKIDefaultKeySpec","2")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.SetInfo()'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("pKIMaxIssuingDepth","0")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("pKICriticalExtensions","2.5.29.15")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("pKIExtendedKeyUsage","1.3.6.1.5.5.7.3.9")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("pKIDefaultCSPs","1,Microsoft Software Key Storage Provider")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("msPKI-RA-Signature","0")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value "$msPKI"
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("msPKI-Enrollment-Flag","20480")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("msPKI-Private-Key-Flag","0")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("msPKI-Certificate-Name-Flag","402653184")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("msPKI-Minimal-Key-Size","2048")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("msPKI-Template-Schema-Version","3")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("msPKI-Template-Minor-Revision","8")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.11803725.16015575.3099577.1880784.14317363.53.1.32")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.put("msPKI-Certificate-Application-Policy","1.3.6.1.5.5.7.3.9")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.SetInfo()'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$BaseNewOCSPTempl = $ADSI.psbase.children | where {$_.displayName -eq "OCSP Response Signing"}'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$BaseWebTempl = $ADSI.psbase.children | where {$_.displayName -eq "Web Server"}'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.pKIKeyUsage = $BaseNewOCSPTempl.pKIKeyUsage'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.pKIExpirationPeriod = $BaseWebTempl.pKIExpirationPeriod'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.pKIOverlapPeriod = $BaseWebTempl.pKIOverlapPeriod'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.SetInfo()'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl | select *'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$acl = $NewOCSPTempl.psbase.ObjectSecurity'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$acl | select -ExpandProperty Access'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$AdObj = New-Object System.Security.Principal.NTAccount("Authenticated Users")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$identity = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$adRights = "ReadProperty, ExtendedRight, GenericExecute"'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$type = "Allow"'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity,$adRights,$type)'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.psbase.ObjectSecurity.SetAccessRule($ACE)'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewOCSPTempl.psbase.commitchanges()'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '# Create SCEP Certificate Template'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl = $ADSI.Create("pKICertificateTemplate", "CN=SCEPCertificate1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("distinguishedName","CN=SCEPCertificate1,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("flags","131680")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("displayName","SCEP Certificate1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("revision","100")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("pKIDefaultKeySpec","1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.SetInfo()'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("pKIMaxIssuingDepth","0")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("pKICriticalExtensions","2.5.29.15;2.5.29.7")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("pKIExtendedKeyUsage","1.3.6.1.5.5.7.3.2")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("pKIDefaultCSPs","1,Microsoft RSA SChannel Cryptographic Provider")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("msPKI-RA-Signature","0")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("msPKI-Enrollment-Flag","1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("msPKI-Private-Key-Flag","16842752")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("msPKI-Certificate-Name-Flag","1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("msPKI-Minimal-Key-Size","2048")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("msPKI-Template-Schema-Version","2")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("msPKI-Template-Minor-Revision","2")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.1973513.3865696.13125792.7702499.9459796.17.693797.11680466")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.put("msPKI-Certificate-Application-Policy","1.3.6.1.5.5.7.3.2")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.SetInfo()'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$BaseSCEPTempl = $ADSI.psbase.children | where {$_.displayName -eq "Workstation Authentication"}'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.pKIKeyUsage = $BaseSCEPTempl.pKIKeyUsage'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.pKIExpirationPeriod = $BaseSCEPTempl.pKIExpirationPeriod'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.pKIOverlapPeriod = $BaseSCEPTempl.pKIOverlapPeriod'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.SetInfo()'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl | select *'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$acl = $NewSCEPTempl.psbase.ObjectSecurity'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$acl | select -ExpandProperty Access'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$AdObj = New-Object System.Security.Principal.NTAccount("Authenticated Users")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$identity = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$adRights = "ReadProperty, ExtendedRight, GenericExecute"'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$type = "Allow"'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity,$adRights,$type)'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.psbase.ObjectSecurity.SetAccessRule($ACE)'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSCEPTempl.psbase.commitchanges()'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '# Create Smartcard User Certificate Template'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl = $ADSI.Create("pKICertificateTemplate", "CN=SmartcardUser1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("distinguishedName","CN=SmartcardUser1,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("flags","131594")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("displayName","Smartcard User1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("revision","100")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("pKIDefaultKeySpec","1")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.SetInfo()'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("pKIMaxIssuingDepth","0")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("pKICriticalExtensions","2.5.29.15")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("pKIExtendedKeyUsage","1.3.6.1.4.1.311.20.2.2; 1.3.6.1.5.5.7.3.2; 1.3.6.1.5.5.7.3.4")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("msPKI-RA-Signature","0")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("msPKI-Enrollment-Flag","41")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("msPKI-Private-Key-Flag","16842768")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("msPKI-Certificate-Name-Flag","-1509949440")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("msPKI-Minimal-Key-Size","2048")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("msPKI-Template-Schema-Version","2")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("msPKI-Template-Minor-Revision","3")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.6099220.12476852.9127614.9757999.5841059.20.10846493.6645440")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.put("msPKI-Certificate-Application-Policy","1.3.6.1.4.1.311.20.2.2; 1.3.6.1.5.5.7.3.2; 1.3.6.1.5.5.7.3.4")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.SetInfo()'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$BaseSmartCardTempl = $ADSI.psbase.children | where {$_.displayName -eq "Smartcard User"}'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.pKIKeyUsage = $BaseSmartCardTempl.pKIKeyUsage'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.pKIExpirationPeriod = $BaseSmartCardTempl.pKIExpirationPeriod'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.pKIOverlapPeriod = $BaseSmartCardTempl.pKIOverlapPeriod'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.SetInfo()'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl | select *'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$acl = $NewSmartCardTempl.psbase.ObjectSecurity'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$acl | select -ExpandProperty Access'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$AdObj = New-Object System.Security.Principal.NTAccount("Authenticated Users")'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$identity = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$adRights = "ReadProperty, ExtendedRight, GenericExecute"'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$type = "Allow"'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity,$adRights,$type)'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.psbase.ObjectSecurity.SetAccessRule($ACE)'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value '$NewSmartCardTempl.psbase.commitchanges()'

                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value 'certsrv'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value 'Start-Sleep 30'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value 'Add-CATemplate -Name "WebServer1" -Force'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value 'Add-CATemplate -Name "OCSPResponseSigning1" -Force'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value 'Add-CATemplate -Name "SCEPCertificate1" -Force'
                Add-Content -Path C:\CertEnroll\Create_CA_Templates.ps1 -Value 'Add-CATemplate -Name "SmartcardUser1" -Force'

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
            DependsOn = '[Script]ConfigureEnterpriseCA'
        }
   
     }
  }