configuration DEFENDERSTIG
{

   param
   (
        [String]$DEFENDERSTIGMOFSASUrl
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
            DestinationPath = 'C:\DEFENDERSTIG-MOF'
            Ensure = "Present"
        }

        File CopyWindowsDefenderXML
        {
            Ensure = "Present"
            Type = "File"
            SourcePath = "C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\4.16.0\StigData\Processed\WindowsDefender-All-2.4.org.default.xml"
            DestinationPath = "C:\DEFENDERSTIG-MOF\WindowsDefender-All-2.4.org.1.0.xml"
            DependsOn = '[File]STIGArtifacts'
        }

        xRemoteFile DEFENDERSTIGMOF
        {
            DestinationPath = "C:\DEFENDERSTIG-MOF\DEFENDERSTIG-MOF.ps1"
            Uri             = $DEFENDERSTIGMOFSASUrl
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = '[File]CopyWindowsDefenderXML'
        }

        Script WaitForFileDownload
        {
            SetScript =
            {
                $FileCheck = Get-ChildItem -Path C:\DEFENDERSTIG-MOF\DEFENDERSTIG-MOF.ps1 -ErrorAction 0
                while (($FileCheck -eq $Null)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\DEFENDERSTIG-MOF\DEFENDERSTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to start downloading"
                }

                while (($FileCheck.Length -ne 433)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\DEFENDERSTIG-MOF\DEFENDERSTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to finish downloading"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]DEFENDERSTIGMOF'
        }

        Script CreateDefenderMOF
        {
            SetScript =
            {
                . C:\DEFENDERSTIG-MOF\DEFENDERSTIG-MOF.ps1
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]WaitForFileDownload'
        }

        Script APPLYDEFENDERSTIG
        {
            SetScript =
            {
                Start-DscConfiguration -Path C:\DEFENDERSTIG-MOF -Force
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]CreateDefenderMOF'
        }
    }
}