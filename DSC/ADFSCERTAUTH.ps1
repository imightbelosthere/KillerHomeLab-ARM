configuration ADFSCERTAUTH
{
   param
   (
        [String]$ExchangeExistsVersion,
        [String]$ExternalDomainName,
        [String]$EXServerIP,
        [String]$NetBiosDomain,     
        [System.Management.Automation.PSCredential]$Admincreds
    )

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        File MachineConfig
        {
            Type = 'Directory'
            DestinationPath = 'C:\MachineConfig'
            Ensure = "Present"
        }

        File ADFSCertificates
        {
            Type = 'Directory'
            DestinationPath = 'C:\ADFS-Certificates'
            Ensure = "Present"
        }

        File WAPCertificates
        {
            Type = 'Directory'
            DestinationPath = 'C:\WAP-Certificates'
            Ensure = "Present"
        }

        File EXCertificates
        {
            Type = 'Directory'
            DestinationPath = 'C:\EX-Certificates'
            Ensure = "Present"
        }

        File CopyEXCertFromExchange
        {
            Ensure = "Present"
            Type = "Directory"
            Recurse = $true
            SourcePath = "\\$EXServerIP\c$\Certificates"
            DestinationPath = "C:\EX-Certificates\"
            Credential = $DomainCreds
            DependsOn = '[File]EXCertificates'
        }

        Script ImportExchangeCertificate
        {
            SetScript =
            {
                # Create Credentials
                $Load = "$using:AdminCreds"
                $Password = $AdminCreds.Password

                #Check if Exchange Certificate already exists if NOT Import
                $exthumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=owa20$using:ExchangeExistsVersion.$using:ExternalDomainName"}).Thumbprint
                IF ($exthumbprint -eq $null) {Import-PfxCertificate -FilePath "C:\EX-Certificates\owa20$using:ExchangeExistsVersion.$using:ExternalDomainName.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $Password}
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[File]EXCertificates'
        }

        Script ConfigureExchange
        {
            SetScript =
            {
                $RulesFile = Get-ChildItem -Path C:\MachineConfig\IssuanceAuthorizationRules.txt -ErrorAction 0
                IF ($RulesFile -eq $null)
                {
                # Create Issuance Authorization Rules File
                Set-Content -Path C:\MachineConfig\IssuanceAuthorizationRules.txt -Value '@RuleTemplate = "AllowAllAuthzRule"'
                Add-Content -Path C:\MachineConfig\IssuanceAuthorizationRules.txt -Value '=> issue(Type = "http://schemas.microsoft.com/authorization/claims/permit",'
                Add-Content -Path C:\MachineConfig\IssuanceAuthorizationRules.txt -Value 'Value = "true");'

                # Create Issuance Transform Rules File
                Set-Content -Path C:\MachineConfig\IssuanceTransformRules.txt -Value '@RuleName = "ActiveDirectoryUserSID"'
                Add-Content -Path C:\MachineConfig\IssuanceTransformRules.txt -Value 'c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", Issuer == "AD AUTHORITY"]'
                Add-Content -Path C:\MachineConfig\IssuanceTransformRules.txt -Value '=> issue(store = "Active Directory", types = ("http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid"), query = ";objectSID;{0}", param = c.Value);'
                Add-Content -Path C:\MachineConfig\IssuanceTransformRules.txt -Value '@RuleName = "ActiveDirectoryUPN"'
                Add-Content -Path C:\MachineConfig\IssuanceTransformRules.txt -Value 'c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", Issuer == "AD AUTHORITY"]'
                Add-Content -Path C:\MachineConfig\IssuanceTransformRules.txt -Value '=> issue(store = "Active Directory", types = ("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"), query = ";userPrincipalName;{0}", param = c.Value);'

                Import-Module ADFS
                
                # Create Relying Pary Trust Script
                [string]$IssuanceAuthorizationRules=Get-Content -Path C:\MachineConfig\IssuanceAuthorizationRules.txt
                [string]$IssuanceTransformRules=Get-Content -Path C:\MachineConfig\IssuanceTransformRules.txt

                # Create Relying Party Trusts
                Add-ADFSRelyingPartyTrust -Name "Outlook Web App 20$using:ExchangeVersion" -Enabled $true -Notes "This is a trust for https://owa20$using:ExchangeExistsVersion.$using:ExternalDomainName/owa/" -WSFedEndpoint "https://owa20$using:ExchangeExistsVersion.$using:ExternalDomainName/owa/" -Identifier "https://owa20$using:ExchangeExistsVersion.$using:ExternalDomainName/owa/" -IssuanceTransformRules $IssuanceTransformRules -IssuanceAuthorizationRules $IssuanceAuthorizationRules
                Add-ADFSRelyingPartyTrust -Name "Exchange Admin Center (EAC) 20$using:ExchangeVersion" -Enabled $true -Notes "This is a trust for https://owa20$using:ExchangeExistsVersion.$using:ExternalDomainName/ecp/" -WSFedEndpoint "https://owa20$using:ExchangeExistsVersion.$using:ExternalDomainName/ecp/" -Identifier "https://owa20$using:ExchangeExistsVersion.$using:ExternalDomainName/ecp/" -IssuanceTransformRules $IssuanceTransformRules -IssuanceAuthorizationRules $IssuanceAuthorizationRules

                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
            DependsOn = '[Script]ImportExchangeCertificate'
        }
    }
}