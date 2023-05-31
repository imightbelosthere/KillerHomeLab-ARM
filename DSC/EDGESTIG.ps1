configuration EDGESTIG
{

   param
   (
        [String]$EDGESTIGMOFSASUrl
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
            DestinationPath = 'C:\EDGESTIG-MOF'
            Ensure = "Present"
        }

        File CopyMicrosoftEdgeXML
        {
            Ensure = "Present"
            Type = "File"
            SourcePath = "C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\4.16.0\StigData\Processed\MS-Edge-1.6.org.default.xml"
            DestinationPath = "C:\EDGESTIG-MOF\MS-Edge-1.6.org.1.0.xml"
            DependsOn = '[File]STIGArtifacts'
        }

        xRemoteFile EDGESTIGMOF
        {
            DestinationPath = "C:\EDGESTIG-MOF\EDGESTIG-MOF.ps1"
            Uri             = $EDGESTIGMOFSASUrl
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = '[File]CopyMicrosoftEdgeXML'
        }

        Script WaitForFileDownload
        {
            SetScript =
            {
                $FileCheck = Get-ChildItem -Path C:\EDGESTIG-MOF\EDGESTIG-MOF.ps1 -ErrorAction 0
                while (($FileCheck -eq $Null)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\EDGESTIG-MOF\EDGESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to start downloading"
                }

                while (($FileCheck.Length -ne 405)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\EDGESTIG-MOF\EDGESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to finish downloading"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]EDGESTIGMOF'
        }

        Script CreateEdgeMOF
        {
            SetScript =
            {
                . C:\EDGESTIG-MOF\EDGESTIG-MOF.ps1
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]WaitForFileDownload'
        }

        Script APPLYEDGESTIG
        {
            SetScript =
            {
                Start-DscConfiguration -Path C:\EDGESTIG-MOF -Force
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]CreateEdgeMOF'
        }
    }
}