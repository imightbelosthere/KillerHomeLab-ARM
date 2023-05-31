configuration FIREWALLSTIG
{

   param
   (
        [String]$FIREWALLSTIGMOFSASUrl,
        [System.Management.Automation.PSCredential]$Admincreds                                  
    )

    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile


    Node localhost
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = "StopConfiguration"
            ConfigurationMode = "ApplyOnly"
        }

        Script EnableTls12
        {
            SetScript =
            {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

        File STIGArtifacts
        {
            Type = 'Directory'
            DestinationPath = 'C:\FIREWALLSTIG-MOF'
            Ensure = "Present"
        }

        File CopyWindowsFirewallXML
        {
            Ensure = "Present"
            Type = "File"
            SourcePath = "C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\4.16.0\StigData\Processed\WindowsFirewall-All-2.1.org.default.xml"
            DestinationPath = "C:\FIREWALLSTIG-MOF\WindowsFirewall-All-2.1.org.1.0.xml"
            DependsOn = '[File]STIGArtifacts'
        }

        xRemoteFile FIREWALLSTIGMOF
        {
            DestinationPath = "C:\FIREWALLSTIG-MOF\FIREWALLSTIG-MOF.ps1"
            Uri             = $FIREWALLSTIGMOFSASUrl
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = '[File]CopyWindowsFirewallXML'
        }

        Script WaitForFileDownload
        {
            SetScript =
            {
                $FileCheck = Get-ChildItem -Path C:\FIREWALLSTIG-MOF\FIREWALLSTIG-MOF.ps1 -ErrorAction 0
                while (($FileCheck -eq $Null)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\FIREWALLSTIG-MOF\FIREWALLSTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to start downloading"
                }

                while (($FileCheck.Length -ne 433)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\FIREWALLSTIG-MOF\FIREWALLSTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to finish downloading"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]FIREWALLSTIGMOF'
        }

        Script CreateFirewallMOF
        {
            SetScript =
            {
                . C:\FIREWALLSTIG-MOF\FIREWALLSTIG-MOF.ps1
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]WaitForFileDownload'
        }

        Script APPLYFIREWALLSTIG
        {
            SetScript =
            {
                Start-DscConfiguration -Path C:\FIREWALLSTIG-MOF -Force
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]CreateFirewallMOF'
        }
    }
}