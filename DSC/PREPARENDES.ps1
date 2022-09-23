configuration PREPARENDES
{
   param
   (
        [String]$computerName,
        [String]$NamingConvention,
        [String]$NetBiosDomain,
        [String]$InternaldomainName,
        [String]$EnterpriseCAName,
        [String]$EnterpriseCAServer,
        [String]$Account,
        [System.Management.Automation.PSCredential]$Admincreds   
    )

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($AdminCreds.UserName)", $AdminCreds.Password)

    Node localhost
    {
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

        Script ConfigureNDES
        {
            SetScript =
            {
                $Load = "$using:DomainCreds"
                $Domain = $DomainCreds.GetNetworkCredential().Domain
                $Username = $DomainCreds.GetNetworkCredential().UserName
                $Password = $DomainCreds.GetNetworkCredential().Password

                $file = Get-Item -Path "C:\NDES-Software\Install_NDES.ps1" -ErrorAction 0
                IF ($file -eq $Null){
                    Set-Content -Path C:\NDES-Software\Install_NDES.ps1 -Value "Install-AdcsNetworkDeviceEnrollmentService -ServiceAccountName $using:NetBiosDomain\$using:Account -ServiceAccountPassword $Password -CAConfig $using:EnterpriseCAServer\$using:EnterpriseCAName -RAName $using:NamingConvention-NDES-RA -RACountry 'US' -RACompany $using:NamingConvention -SigningProviderName 'Microsoft Strong Cryptographic Provider' -SigningKeyLength 4096 -EncryptionProviderName 'Microsoft Strong Cryptographic Provider' -EncryptionKeyLength 4096"
                }

                # Install NDES
                $scheduledtask = Get-ScheduledTask "Install NDES" -ErrorAction 0
                $action = New-ScheduledTaskAction -Execute Powershell -Argument '.\Install_NDES.ps1' -WorkingDirectory 'C:\NDES-Software'
                IF ($scheduledtask -eq $null) {
                    Register-ScheduledTask -Action $action -TaskName "Install NDES" -Description "Install NDES Role" -User $Domain\$Username -Password $Password
                    Start-ScheduledTask "Install NDES"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]SetSPN'
        }
    }
}