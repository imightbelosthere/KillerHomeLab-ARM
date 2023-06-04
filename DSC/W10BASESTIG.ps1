configuration W10BASESTIG
{

   param
   (
        [String]$W10BASESTIGMOFSASUrl
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
            DestinationPath = 'C:\W10BASESTIG-MOF'
            Ensure = "Present"
        }

        File CopyWindowsClientXML
        {
            Ensure = "Present"
            Type = "File"
            SourcePath = "C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\4.16.0\StigData\Processed\WindowsClient-10-2.5.org.default.xml"
            DestinationPath = "C:\W10BASESTIG-MOF\WindowsClient-10-2.5.org.1.0.xml"
            DependsOn = '[File]STIGArtifacts'
        }

        xRemoteFile W10BASESTIGMOF
        {
            DestinationPath = "C:\W10BASESTIG-MOF\W10BASESTIG-MOF.ps1"
            Uri             = $W10BASESTIGMOFSASUrl
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = '[File]CopyWindowsClientXML'
        }

        Script WaitForFileDownload
        {
            SetScript =
            {
                $FileCheck = Get-ChildItem -Path C:\W10BASESTIG-MOF\W10BASESTIG-MOF.ps1 -ErrorAction 0
                while (($FileCheck -eq $Null)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\W10BASESTIG-MOF\W10BASESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to start downloading"
                }

                while (($FileCheck.Length -ne 873)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\W10BASESTIG-MOF\W10BASESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to finish downloading"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]W10BASESTIGMOF'
        }

        Script CreateWindowsClientMOF
        {
            SetScript =
            {
                . C:\W10BASESTIG-MOF\W10BASESTIG-MOF.ps1
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]WaitForFileDownload'
        }

        Script APPLYW10BASESTIG
        {
            SetScript =
            {
                Start-DscConfiguration -Path C:\W10BASESTIG-MOF -Force
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]CreateWindowsClientMOF'
        }
    }
}