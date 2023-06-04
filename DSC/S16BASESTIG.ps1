configuration S16BASESTIG
{

   param
   (
        [String]$S16BASESTIGMOFSASUrl
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
            DestinationPath = 'C:\S16BASESTIG-MOF'
            Ensure = "Present"
        }

        File CopyWindowsServerXML
        {
            Ensure = "Present"
            Type = "File"
            SourcePath = "C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\4.16.0\StigData\Processed\WindowsServer-2016-MS-2.5.org.default.xml"
            DestinationPath = "C:\S16BASESTIG-MOF\WindowsServer-2016-MS-2.5.org.1.0.xml"
            DependsOn = '[File]STIGArtifacts'
        }

        xRemoteFile S16BASESTIGMOF
        {
            DestinationPath = "C:\S16BASESTIG-MOF\S16BASESTIG-MOF.ps1"
            Uri             = $S16BASESTIGMOFSASUrl
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = '[File]CopyWindowsServerXML'
        }

        Script WaitForFileDownload
        {
            SetScript =
            {
                $FileCheck = Get-ChildItem -Path C:\S16BASESTIG-MOF\S16BASESTIG-MOF.ps1 -ErrorAction 0
                while (($FileCheck -eq $Null)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\S16BASESTIG-MOF\S16BASESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to start downloading"
                }

                while (($FileCheck.Length -ne 794)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\S16BASESTIG-MOF\S16BASESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to finish downloading"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]S16BASESTIGMOF'
        }

        Script CreateWindowsServerMOF
        {
            SetScript =
            {
                . C:\S16BASESTIG-MOF\S16BASESTIG-MOF.ps1
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]WaitForFileDownload'
        }

        Script APPLYS16BASESTIG
        {
            SetScript =
            {
                Start-DscConfiguration -Path C:\S16BASESTIG-MOF -Force
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]CreateWindowsServerMOF'
        }
    }
}