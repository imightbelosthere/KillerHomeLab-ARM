configuration FIRSTADFSENT
{
   param
   (
        [String]$ExternalDomainName,           
        [String]$NetBiosDomain,
        [String]$EnterpriseCAName,
        [System.Management.Automation.PSCredential]$Admincreds


    )
    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature ADFS-Federation
        {
            Ensure = 'Present'
            Name   = 'ADFS-Federation'
        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZone
        }

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

        Script CreateADFSCertExport
        {
            SetScript =
            {
                # Create Credentials
                $User = Get-ChildItem Env:\USERNAME
                $Domain = "$using:NetBiosDomain"
                $ProtectAccount = $Domain + "\" + $User.Value
                $fsgmsa = 'FsGmsa$'

                $CertCheck = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=adfs.$using:ExternalDomainName"}
                IF ($CertCheck -eq $null)
                {
                    # Export Service Communication Certificate
                    $ServiceCert = Get-ChildItem -Path "C:\ADFS-Certificates\adfs.$using:ExternalDomainName.pfx" -ErrorAction 0
                    IF ($ServiceCert -eq $null)
                    {

                        # Get Old Files
                        $Oldfiles = Get-ChildItem C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys
                        $OldFileNames = @()
                        foreach ($OldFile in $OldFiles){
                            $OldFileNames += Get-ChildItem C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys -Name $OldFile.Name
                        }

                        # Get Service Communication Certificate and Export it
                        Get-Certificate -Template WebServer1 -SubjectName "CN=adfs.$using:ExternalDomainName" -DNSName "adfs.$using:ExternalDomainName" -CertStoreLocation "cert:\LocalMachine\My"
                        $ServiceThumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=adfs.$using:ExternalDomainName"}).Thumbprint                 
                        Get-ChildItem -Path cert:\LocalMachine\my\$ServiceThumbprint | Export-PfxCertificate -FilePath "C:\ADFS-Certificates\adfs.$using:ExternalDomainName.pfx" -ProtectTo $ProtectAccount

                        # Get New Files
                        $Newfiles = Get-ChildItem C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys
                        $NewFileNames = @()
                        foreach ($NewFile in $NewFiles){
                            $NewFileNames += Get-ChildItem C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys -Name $NewFile.Name
                        }

                        # Get New Cert Hash
                        $DeltaFile = Compare-Object $OldFileNames $NewFileNames

                        # Add Private Key Permissions
                        $account = "$Domain\$fsgmsa"
                        $FullPath = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys"+"\"+$DeltaFile.InputObject                    
                        $acl=(Get-Item $fullPath).GetAccessControl('Access')
                        $permission=$account,"Full","Allow"
                        $accessRule=new-object System.Security.AccessControl.FileSystemAccessRule $permission
                        $acl.AddAccessRule($accessRule)
                        Set-Acl $fullPath $acl
                    }

                    $SigningCert = Get-ChildItem -Path "C:\ADFS-Certificates\adfs-signing.$using:ExternalDomainName.pfx" -ErrorAction 0
                    IF ($SigningCert -eq $null)
                    {
                        # Get Old Files
                        $Oldfiles = Get-ChildItem C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys
                        $OldFileNames = @()
                        foreach ($OldFile in $OldFiles){
                            $OldFileNames += Get-ChildItem C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys -Name $OldFile.Name
                        }

                        # Get Signing Certificate and Export it
                        Get-Certificate -Template WebServer1 -SubjectName "CN=adfs-signing.$using:ExternalDomainName" -DNSName "adfs-signing.$using:ExternalDomainName" -CertStoreLocation "cert:\LocalMachine\My"
                        $SigningThumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=adfs-signing.$using:ExternalDomainName"}).Thumbprint                 
                        Get-ChildItem -Path cert:\LocalMachine\my\$SigningThumbprint | Export-PfxCertificate -FilePath "C:\ADFS-Certificates\adfs-signing.$using:ExternalDomainName.pfx" -ProtectTo $ProtectAccount

                        # Get New Files
                        $Newfiles = Get-ChildItem C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys
                        $NewFileNames = @()
                        foreach ($NewFile in $NewFiles){
                            $NewFileNames += Get-ChildItem C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys -Name $NewFile.Name
                        }

                        # Get New Cert Hash
                        $DeltaFile = Compare-Object $OldFileNames $NewFileNames

                        # Add Private Key Permissions
                        $account = "$Domain\$fsgmsa"
                        $FullPath = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys"+"\"+$DeltaFile.InputObject                    
                        $acl=(Get-Item $fullPath).GetAccessControl('Access')
                        $permission=$account,"Full","Allow"
                        $accessRule=new-object System.Security.AccessControl.FileSystemAccessRule $permission
                        $acl.AddAccessRule($accessRule)
                        Set-Acl $fullPath $acl
                    }
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
            DependsOn = '[File]ADFSCertificates'
        }

        Script CreateWAPCertExport
        {
            SetScript =
            {
                # Create Credentials
                $Load = "$using:DomainCreds"
                $Password = $DomainCreds.Password

                # Export Service Communication Certificate
                $ServiceCert = Get-ChildItem -Path "C:\WAP-Certificates\adfs.$using:ExternalDomainName.pfx" -ErrorAction 0
                IF ($ServiceCert -eq $null)
                {
                    $ServiceThumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=adfs.$using:ExternalDomainName"}).Thumbprint                 
                    Get-ChildItem -Path cert:\LocalMachine\my\$ServiceThumbprint | Export-PfxCertificate -FilePath "C:\WAP-Certificates\adfs.$using:ExternalDomainName.pfx" -Password $Password
                }

                # Export Root CA
                $EnterpriseCert = Get-ChildItem -Path "C:\WAP-Certificates\$using:EnterpriseCAName.cer" -ErrorAction 0
                IF ($EnterpriseCert -eq $null)
                {
                    $EnterpriseExport = Get-ChildItem -Path cert:\Localmachine\Root\ | Where-Object {$_.Subject -like "CN=$using:EnterpriseCAName*"}
                    Export-Certificate -Cert $EnterpriseExport -FilePath "C:\WAP-Certificates\$using:EnterpriseCAName.cer" -Type CER
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[File]WAPCertificates','[Script]CreateADFSCertExport'
        }

        Script ConfigureADFS
        {
            SetScript =
            {
                $RulesFile = Get-ChildItem -Path C:\ADFS-Certificates\ADFSSigningThumb.txt -ErrorAction 0
                IF ($RulesFile -eq $null)
                {
                # Get Service Communication Certificate
                $ServiceThumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=adfs.$using:ExternalDomainName"}).Thumbprint

                # Get Token Signing Certificate
                $SigningThumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=adfs-signing.$using:ExternalDomainName"}).Thumbprint

                Import-Module ADFS
                Install-AdfsFarm -CertificateThumbprint $ServiceThumbprint -FederationServiceName "adfs.$using:ExternalDomainName" -GroupServiceAccountIdentifier "$using:NetBiosDomain\FsGmsa$"

                # Turn off Certificate Auto Certificate Rollover
                Set-ADFSProperties -AutoCertificateRollover $False
                
                # Add Token Signing Certificate
                Add-AdfsCertificate -CertificateType "Token-Signing" -Thumbprint $SigningThumbprint

                # Set Token Signing Certificate
                Set-AdfsCertificate -IsPrimary -CertificateType "Token-Signing" -Thumbprint $SigningThumbprint
                
                # Remove Self-Signed Certificate
                Get-AdfsCertificate | Where-Object {$_.CertificateType -eq 'Token-Signing'} | Where-Object {$_.IsPrimary -ne 'True'} | Remove-AdfsCertificate

                # Export ADFS Signing Thumbprint
                (Get-AdfsCertificate | Where {$_.CertificateType -like "Token-Signing"}).Thumbprint > "C:\ADFS-Certificates\ADFSSigningThumb.txt"

                # Enable Certificate Copy
                $EnableSMB = Get-NetFirewallRule "FPS-SMB-In-TCP" -ErrorAction 0
                IF ($EnableSMB -ne $null) {Enable-NetFirewallRule -Name "FPS-SMB-In-TCP"}

                # Enable Test Sign-In
                Set-AdfsProperties -EnableIdPInitiatedSignonPage $true
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
            DependsOn = '[Script]CreateWAPCertExport'
        }
    }
}