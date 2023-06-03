configuration S22BASESTIG
{

   param
   (
        [String]$S22BASESTIGMOFSASUrl
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
            DestinationPath = 'C:\S22BASESTIG-MOF'
            Ensure = "Present"
        }

        File CopyWindowsServerXML
        {
            Ensure = "Present"
            Type = "File"
            SourcePath = "C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\4.16.0\StigData\Processed\WindowsServer-2022-MS-1.1.org.default.xml"
            DestinationPath = "C:\S22BASESTIG-MOF\WindowsServer-2022-MS-1.1.org.1.0.xml"
            DependsOn = '[File]STIGArtifacts'
        }

        xRemoteFile S22BASESTIGMOF
        {
            DestinationPath = "C:\S22BASESTIG-MOF\S22BASESTIG-MOF.ps1"
            Uri             = $S22BASESTIGMOFSASUrl
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = '[File]CopyWindowsServerXML'
        }

        Script WaitForFileDownload
        {
            SetScript =
            {
                $FileCheck = Get-ChildItem -Path C:\S22BASESTIG-MOF\S22BASESTIG-MOF.ps1 -ErrorAction 0
                while (($FileCheck -eq $Null)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\S22BASESTIG-MOF\S22BASESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to start downloading"
                }

                while (($FileCheck.Length -ne 1045)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\S22BASESTIG-MOF\S22BASESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to finish downloading"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]S22BASESTIGMOF'
        }

        Script CreateWindowsServerMOF
        {
            SetScript =
            {
                . C:\S22BASESTIG-MOF\S22BASESTIG-MOF.ps1
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]WaitForFileDownload'
        }

        Script APPLYS22BASESTIG
        {
            SetScript =
            {
                Start-DscConfiguration -Path C:\S22BASESTIG-MOF -Force
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]CreateWindowsServerMOF'
        }
    }
}