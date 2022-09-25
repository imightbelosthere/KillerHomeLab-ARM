configuration SCEPCATEMPLATE
{
   param
   (
        [String]$NetBiosDomain,
        [String]$ServiceAccountName,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        Script CreateSCEPCATemplates
        {
            SetScript =
            {
                $Load = "$using:DomainCreds"
                $Domain = $DomainCreds.GetNetworkCredential().Domain
                $Username = $DomainCreds.GetNetworkCredential().UserName
                $Password = $DomainCreds.GetNetworkCredential().Password


                $ServiceAccountTransfer = "$using:ServiceAccountName"
                $ServiceAccount = '"'+$ServiceAccountTransfer+'"'
                Set-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '# Set AD Context'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"'

                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '# Create SCEP Certificate Template'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl = $ADSI.Create("pKICertificateTemplate", "CN=SCEPCertificate")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("distinguishedName","CN=SCEPCertificate,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("flags","131680")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("displayName","SCEP Certificate")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("revision","100")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("pKIDefaultKeySpec","1")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.SetInfo()'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("pKIMaxIssuingDepth","0")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("pKICriticalExtensions","2.5.29.15;2.5.29.7")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("pKIExtendedKeyUsage","1.3.6.1.5.5.7.3.2")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("pKIDefaultCSPs","1,Microsoft RSA SChannel Cryptographic Provider")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("msPKI-RA-Signature","0")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("msPKI-Enrollment-Flag","1")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("msPKI-Private-Key-Flag","16842752")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("msPKI-Certificate-Name-Flag","1")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("msPKI-Minimal-Key-Size","2048")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("msPKI-Template-Schema-Version","2")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("msPKI-Template-Minor-Revision","2")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.7183632.6046387.16009101.13536898.4471759.164.5869043.12046343")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.put("msPKI-Certificate-Application-Policy","1.3.6.1.5.5.7.3.2")'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.SetInfo()'

                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$BaseSCEPTempl = $ADSI.psbase.children | where {$_.displayName -eq "Workstation Authentication"}'

                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.pKIKeyUsage = $BaseSCEPTempl.pKIKeyUsage'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.pKIExpirationPeriod = $BaseSCEPTempl.pKIExpirationPeriod'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.pKIOverlapPeriod = $BaseSCEPTempl.pKIOverlapPeriod'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.SetInfo()'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl | select *'

                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$acl = $NewSCEPTempl.psbase.ObjectSecurity'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$acl | select -ExpandProperty Access'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value "$AdObj = New-Object System.Security.Principal.NTAccount($ServiceAccount)"
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$identity = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$adRights = "ReadProperty, ExtendedRight, GenericExecute"'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$type = "Allow"'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity,$adRights,$type)'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.psbase.ObjectSecurity.SetAccessRule($ACE)'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '$NewSCEPTempl.psbase.commitchanges()'

                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value '# Add Templates'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value 'certsrv'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value 'Start-Sleep 30'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value 'Restart-Service CertSvc'
                Add-Content -Path C:\CertEnroll\Create_SCEP_CA_Template.ps1 -Value 'Add-CATemplate -Name "SCEPCertificate" -Force'

                # Create SCEP CA Templates
                $scheduledtask = Get-ScheduledTask "Create SCEP CA Templates" -ErrorAction 0
                $action = New-ScheduledTaskAction -Execute Powershell -Argument '.\Create_SCEP_CA_Template.ps1' -WorkingDirectory 'C:\CertEnroll'
                IF ($scheduledtask -eq $null) {
                Register-ScheduledTask -Action $action -TaskName "Create SCEP CA Templates" -Description "Create SCEP CA Template" -User $Domain\$Username -Password $Password
                Start-ScheduledTask "Create SCEP CA Templates"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }
    }
}