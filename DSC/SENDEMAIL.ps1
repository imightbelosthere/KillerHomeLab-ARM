configuration SENDEMAIL
{
   param
   (
        [String]$ToEmail,
        [String]$FromEmail,
        [String]$EnterpriseCAServerName,
        [String]$EnterpriseCAName,
        [String]$InternalDomainName,
        [String]$ExchangeServerName,
        [String]$NameServer1,
        [String]$NameServer2,
        [String]$NameServer3,
        [String]$NameServer4,
        [System.Management.Automation.PSCredential]$Admincreds
    )
    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        File DeploymentEmail
        {
            Type = 'Directory'
            DestinationPath = 'C:\Deployment-Email'
            Ensure = "Present"
        }

        Script SendCompletionEmail
        {
            SetScript =
            {
                $u = "_"
                $Att1 = "C:\Windows\System32\certsrv\CertEnroll\$using:EnterpriseCAServerName.$using:InternalDomainName$u$using:EnterpriseCAName.crt"
                
                $CreateAtt3 = Get-ChildItem -Path C:\Deployment-Email\NameServers.txt -ErrorAction 0
                IF ($CreateAtt3 -eq $null) {                 
                    Add-Content -Path C:\Deployment-Email\NameServers.txt -Value "$using:NameServer1"
                    Add-Content -Path C:\Deployment-Email\NameServers.txt -Value "$using:NameServer2"
                    Add-Content -Path C:\Deployment-Email\NameServers.txt -Value "$using:NameServer3"
                    Add-Content -Path C:\Deployment-Email\NameServers.txt -Value "$using:NameServer4"

                    $Att2 = "C:\Deployment-Email\NameServers.txt" 
                }         
                
                # Build a command that will be run inside the VM.
                Send-MailMessage -To "$using:ToEmail" -From "$using:FromEmail" -Subject "Enterprise Certificate Authority" -Body "Attached is the Enterprise Certificate Authority that is needed to securely connect to OWA." -SmtpServer "$using:ExchangeServerName" -Attachments "$Att1"
                Send-MailMessage -To "$using:ToEmail" -From "$using:FromEmail" -Subject "Azure Public DNS Zone Name Server List" -Body "Attached is a list of Name Servers that can used to update your Name Registrar in order to utilize Azure DNS as your Authoritative DNS Source" -SmtpServer "$using:ExchangeServerName" -Attachments "$Att2"
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
            DependsOn = '[File]DeploymentEmail'
        }
    }
}