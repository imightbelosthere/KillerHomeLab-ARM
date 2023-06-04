configuration S19BASESTIG
{

   param
   (
        [String]$S19BASESTIGMOFSASUrl
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
            DestinationPath = 'C:\S19BASESTIG-MOF'
            Ensure = "Present"
        }

        File CopyWindowsServerXML
        {
            Ensure = "Present"
            Type = "File"
            SourcePath = "C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\4.16.0\StigData\Processed\WindowsServer-2019-MS-2.5.org.default.xml"
            DestinationPath = "C:\S19BASESTIG-MOF\WindowsServer-2019-MS-2.5.org.1.0.xml"
            DependsOn = '[File]STIGArtifacts'
        }

        xRemoteFile S19BASESTIGMOF
        {
            DestinationPath = "C:\S19BASESTIG-MOF\S19BASESTIG-MOF.ps1"
            Uri             = $S19BASESTIGMOFSASUrl
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = '[File]CopyWindowsServerXML'
        }

        Script WaitForFileDownload
        {
            SetScript =
            {
                $FileCheck = Get-ChildItem -Path C:\S19BASESTIG-MOF\S19BASESTIG-MOF.ps1 -ErrorAction 0
                while (($FileCheck -eq $Null)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\S19BASESTIG-MOF\S19BASESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to start downloading"
                }

                while (($FileCheck.Length -ne 791)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\S19BASESTIG-MOF\S19BASESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to finish downloading"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]S19BASESTIGMOF'
        }

        Script CreateWindowsServerMOF
        {
            SetScript =
            {
                . C:\S19BASESTIG-MOF\S19BASESTIG-MOF.ps1
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]WaitForFileDownload'
        }

        Script APPLYS19BASESTIG
        {
            SetScript =
            {
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]CreateWindowsServerMOF'
        }
    }
}