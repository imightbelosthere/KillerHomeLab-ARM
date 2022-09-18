﻿configuration SCEPCATEMPLATE
{
   param
   (
        [String]$NetBiosDomain,
        [String]$CATemplateScriptUrl,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile

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

        xRemoteFile DownloadCreateCATemplates
        {
            DestinationPath = "C:\CertEnroll\Create_SCEP_CA_Template.ps1"
            Uri             = $CATemplateScriptUrl
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = '[Registry]SchUseStrongCrypto', '[Registry]SchUseStrongCrypto64'
        }

        Script CreateCATemplates
        {
            SetScript =
            {
                $Load = "$using:DomainCreds"
                $Domain = $DomainCreds.GetNetworkCredential().Domain
                $Username = $DomainCreds.GetNetworkCredential().UserName
                $Password = $DomainCreds.GetNetworkCredential().Password 

                # Create CA Templates
                $scheduledtask = Get-ScheduledTask "Create SCEP CA Template" -ErrorAction 0
                $action = New-ScheduledTaskAction -Execute Powershell -Argument '.\Create_SCEP_CA_Template.ps1' -WorkingDirectory 'C:\CertEnroll'
                IF ($scheduledtask -eq $null) {
                Register-ScheduledTask -Action $action -TaskName "Create SCEP CA Template" -Description "Create SCEP CA Templates" -User $Domain\$Username -Password $Password
                Start-ScheduledTask "Create CA Templates"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]DownloadCreateCATemplates'
        }
    }
}