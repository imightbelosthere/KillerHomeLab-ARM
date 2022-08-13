configuration DEVOPSSERVER22
{
   param
   (
        [String]$DevOpsServerSASUrl, 
        [String]$TimeZone,                       
        [String]$NetBiosDomain,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile
    Import-DscResource -Module ComputerManagementDsc # Used for TimeZone
    Import-DscResource -Module xStorage # Used by Disk

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        Registry SchUseStrongCrypto
        {
            Key                         = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
            ValueName                   = 'SchUseStrongCrypto'
            ValueType                   = 'Dword'
            ValueData                   =  '1'
            Ensure                      = 'Present'
        }

        Registry SchUseStrongCrypto64
        {
            Key                         = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
            ValueName                   = 'SchUseStrongCrypto'
            ValueType                   = 'Dword'
            ValueData                   =  '1'
            Ensure                      = 'Present'
        }

        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        Script DismountISO
        {
      	    SetScript = {
                Dismount-DiskImage "C:\DevOpsServerInstall\DevOpsServer2022.iso" -ErrorAction 0
            }
            GetScript =  { @{} }
            TestScript = { $false }
        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZone
        }

        File CreateSoftwareFolder
        {
            Type = 'Directory'
            DestinationPath = 'C:\DevOpsServerInstall'
            Ensure = "Present"
        }

        xRemoteFile DownloadDevOpsServer2022
        {
            DestinationPath = "C:\DevOpsServerInstall\DevOpsServer2022.iso"
            Uri             = "$DevOpsServerSASUrl"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn =    '[File]CreateSoftwareFolder'
        }

        xMountImage DevOpsServerISO
        {
            ImagePath   = 'C:\DevOpsServerInstall\DevOpsServer2022.iso'
            DriveLetter = 'I'
            DependsOn = '[xRemoteFile]DownloadDevOpsServer2022'
        }

        xWaitForVolume WaitForISO
        {
            DriveLetter      = 'I'
            RetryIntervalSec = 5
            RetryCount       = 10
        }

        Script InstallDevOpsServer2022Bits
        {
            SetScript =
            {
                $Install = Get-ChildItem -Path C:\DevOpsServerInstall\DeployDevOpsServer.cmd -ErrorAction 0
                IF ($Install -eq $null) {                 
                Set-Content -Path C:\DevOpsServerInstall\DeployDevOpsServer.cmd -Value "I:\AzureDevops2022_RC1.exe /Silent"
                C:\DevOpsServerInstall\DeployDevOpsServer.cmd
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = "[xWaitForVolume]WaitForISO"
        }
    }
}