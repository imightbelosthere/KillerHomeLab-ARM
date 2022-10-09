Configuration WAPINTUNE
{
   param
   (
        [String]$NDESServerIP,
        [String]$ExternalDomainName,
        [System.Management.Automation.PSCredential]$Admincreds
 
    )
 
    Node localhost
    {
        File CopyServiceCommunicationCertFromNDES
        {
            Ensure = "Present"
            Type = "Directory"
            Recurse = $true
            SourcePath = "\\$NDESServerIP\c$\WAP-Certificates"
            DestinationPath = "C:\WAP-Certificates\"
            Credential = $Admincreds
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
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[File]CopyServiceCommunicationCertFromNDES'
        }

        Script ConfigureWAP
        {
            SetScript =
            {
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