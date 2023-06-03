configuration W11BASESTIG
{

   param
   (
        [String]$W11BASESTIGMOFSASUrl
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
            DestinationPath = 'C:\W11BASESTIG-MOF'
            Ensure = "Present"
        }

        File CopyWindowsClientXML
        {
            Ensure = "Present"
            Type = "File"
            SourcePath = "C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\4.16.0\StigData\Processed\WindowsClient-11-1.2.org.default.xml"
            DestinationPath = "C:\W11BASESTIG-MOF\WindowsClient-11-1.2.org.1.0.xml"
            DependsOn = '[File]STIGArtifacts'
        }

        xRemoteFile W11BASESTIGMOF
        {
            DestinationPath = "C:\W11BASESTIG-MOF\W11BASESTIG-MOF.ps1"
            Uri             = $W11BASESTIGMOFSASUrl
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = '[File]CopyWindowsClientXML'
        }

        Script WaitForFileDownload
        {
            SetScript =
            {
                $FileCheck = Get-ChildItem -Path C:\W11BASESTIG-MOF\W11BASESTIG-MOF.ps1 -ErrorAction 0
                while (($FileCheck -eq $Null)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\W11BASESTIG-MOF\W11BASESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to start downloading"
                }

                while (($FileCheck.Length -ne 1045)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\W11BASESTIG-MOF\W11BASESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to finish downloading"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]W11BASESTIGMOF'
        }

        Script CreateWindowsClientMOF
        {
            SetScript =
            {
                . C:\W11BASESTIG-MOF\W11BASESTIG-MOF.ps1
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]WaitForFileDownload'
        }

        Script APPLYW11BASESTIG
        {
            SetScript =
            {
                Start-DscConfiguration -Path C:\W11BASESTIG-MOF -Force
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]CreateWindowsClientMOF'
        }
    }
}