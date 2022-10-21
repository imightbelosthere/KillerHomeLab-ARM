configuration IISSSL
{
   param
   (
        [String]$ComputerName,
        [String]$PFXSASUrl,
        [String]$PFXCommonName,                  
        [System.Management.Automation.PSCredential]$Admincreds,
        [System.Management.Automation.PSCredential]$PFXCreds
    )

    Import-DscResource -Module xPSDesiredStateConfiguration

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

        WindowsFeature Web-Server
        {
            Ensure = 'Present'
            Name = 'Web-Server'
        }

        WindowsFeature Web-Mgmt-Console
        {
            Ensure = 'Present'
            Name = 'Web-Mgmt-Console'
        }

        File Certificates
        {
            Type = 'Directory'
            DestinationPath = 'C:\Certificates'
            Ensure = "Present"
        }

        xRemoteFile DownloadPFX
        {
            DestinationPath = "C:\Certificates\iisssl.pfx"
            Uri             = $PFXSASUrl
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = "[File]Certificates", "[Registry]SchUseStrongCrypto", "[Registry]SchUseStrongCrypto64"
        }

        Script ImportPFX
        {
            SetScript =
            {
                # Create Credentials
                $LoadCreds = "$using:PFXCreds"
                $Password = $PFXCreds.Password
                $PFXCN = "$using:PFXCommonName"
                #Check if LB WWW Certificate already exists if NOT Import
                $lbwwwcert = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like 'CN='+$PFXCN+'*'})
                IF ($lbwwwcert -eq $null) {
                    Import-PfxCertificate -FilePath "C:\Certificates\iisssl.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $Password
                    $Issuer = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like 'CN='+$PFXCN+'*'}).Issuer
                    (Get-ChildItem -Path Cert:\LocalMachine\CA | Where-Object {$_.Subject -like $Issuer}) | Move-Item -Destination Cert:\LocalMachine\Root\
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]DownloadPFX'
        }

        Script ConfigureIIS
        {
            SetScript =
            {
                
                $PFXCN = "$using:PFXCommonName"
                $BindingCheck = Get-WebBinding -Name "Default Web Site" -Protocol https -ErrorAction 0
                IF ($BindingCheck -eq $Null){
                    $cert = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like 'CN='+$PFXCN+'*'})
                    New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https
                    $Binding = Get-WebBinding -Name "Default Web Site" -Protocol https
                    $Binding.AddSslCertificate($cert.GetCertHashString(), "my")
                    $VMName = "$using:ComputerName"
                    (Get-Content -path c:\inetpub\wwwroot\iisstart.htm -Raw) -replace "<body>","<body>$VMName" | Set-Content -Path C:\inetpub\wwwroot\iisstart.htm
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $Admincreds
            DependsOn = '[xRemoteFile]DownloadPFX','[Script]ImportPFX'
        }
    }
}