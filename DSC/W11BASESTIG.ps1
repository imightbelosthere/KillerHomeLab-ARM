configuration W11BASESTIG
{

   param
   (
        [String]$W11BASESTIGMOFSASUrl,
        [System.Management.Automation.PSCredential]$Admincreds                                  
    )

    $ComputerName = $env:COMPUTERNAME
    [System.Management.Automation.PSCredential ]$LocalCreds = New-Object System.Management.Automation.PSCredential ("${ComputerName}\$($AdminCreds.UserName)", $AdminCreds.Password)

    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile
    Import-DscResource -Module ComputerManagementDsc # Used for Scheduled Task


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

        Script InstallPowerSTIG
        {
            SetScript =
            {
                Set-Service -Name "WinRM" -StartupType Automatic
                Start-Service -Name "WinRM"
                $Interface=Get-NetAdapter|Where-Object Name -Like "Ethernet*"|Select-Object -First 1
                $InterfaceAlias=$($Interface.Name)
                Set-NetConnectionProfile -InterfaceAlias $InterfaceAlias -NetworkCategory Private
                Set-Item -Path WSMan:\localhost\MaxEnvelopeSizekb -Value 8192
                Enable-PSRemoting –Force

                Install-PackageProvider -Name NuGet -Force
                Install-Module PowerSTIG -Force
                Import-Module PowerSTIG
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]EnableTls12'
        }

        File STIGArtifacts
        {
            Type = 'Directory'
            DestinationPath = 'C:\W11BASESTIG'
            Ensure = "Present"
            DependsOn = '[Script]InstallPowerSTIG'
        }

        File CopyXML
        {
            Ensure = "Present"
            Type = "File"
            SourcePath = "C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\4.16.0\StigData\Processed\WindowsClient-11-1.2.org.default.xml"
            DestinationPath = "C:\W11BASESTIG\WindowsClient-11-1.2.org.1.0.xml"
            DependsOn = "[File]STIGArtifacts"
        }

        xRemoteFile W11BASESTIGMOF
        {
            DestinationPath = "C:\W11BASESTIG\W11BASESTIG-MOF.ps1"
            Uri             = $W11BASESTIGMOFSASUrl
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = '[File]CopyXML'
        }

        Script WaitForFileDownload
        {
            SetScript =
            {
                $FileCheck = Get-ChildItem -Path C:\W11BASESTIG\W11BASESTIG-MOF.ps1 -ErrorAction 0
                while (($FileCheck -eq $Null)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\W11BASESTIG\W11BASESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to start downloading"
                }

                while (($FileCheck.Length -ne 1037)){
                    Start-Sleep 10
                    $FileCheck = Get-ChildItem -Path C:\W11BASESTIG\W11BASESTIG-MOF.ps1 -ErrorAction 0
                    Write-Host "Waiting for File to finish downloading"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]W11BASESTIGMOF'
        }

        Script CreateMOF
        {
            SetScript =
            {
                . C:\W11BASESTIG\W11BASESTIG-MOF.ps1
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]WaitForFileDownload'
        }

        Script APPLYW11BASESTIG
        {
            SetScript =
            {
                Start-DscConfiguration -Path C:\W11BASESTIG -Verbose -Wait -Force
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]CreateMOF'
        }
    }
}