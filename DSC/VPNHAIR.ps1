configuration VPNHAIR
{
   param
   (
        [String]$ComputerName,
        [String]$Site1Name,
        [String]$Site2Name,
        [String]$Site1RemoteGatewayIP,
        [String]$Site2RemoteGatewayIP,
        [String]$Site1IPv4Subnet,
        [String]$Site2IPv4Subnet,
        [String]$SharedKey,
        [System.Management.Automation.PSCredential]$Admincreds                                  
    )

    Import-DscResource -Module ComputerManagementDsc # Task Scheduler

    [System.Management.Automation.PSCredential ]$LocalCreds = New-Object System.Management.Automation.PSCredential ("${ComputerName}\$($AdminCreds.UserName)", $AdminCreds.Password)

    Node localhost
    {
        File ConfigureRRASDirectory
        {
            Type = 'Directory'
            DestinationPath = 'C:\ConfigureRRAS'
            Ensure = "Present"
        }

        Script ConfigureRRAS
        {
            SetScript =
            {
                # Create ConfigureRRAS Script
                $RemoteAccessValue = '$RemoteAccess'
                $InstallStatusValue = '$InstallStatus'
                $VPNINTSITE1VALUE = '$VPNINTSITE1'
                $VPNINTSITE2VALUE = '$VPNINTSITE2'
                $Site1IPv4 = "$using:Site1IPv4Subnet"+':100'
                $Site2IPv4 = "$using:Site2IPv4Subnet"+':100'
                Set-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value '$RemoteAccess = Get-RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value "IF ($RemoteAccessValue.VpnS2SStatus -ne 'Installed'){"
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value 'Restart-Service -Name RemoteAccess -ErrorAction 0'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value 'Install-RemoteAccess -VpnType VpnS2S'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value 'Import-Module RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value '$RemoteAccess = Get-RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value '$InstallStatus = $RemoteAccess.VpnS2SStatus'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value "while (($InstallStatusValue -ne 'Installed')){sleep 10}"
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value '}'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value '$VPNINT = Get-VpnS2SInterface'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value 'IF ($VPNINT -eq $null){'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value "$VPNINTSITE1VALUE = Get-VpnS2SInterface -Name $using:Site1Name -ErrorAction 0"
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value "$VPNINTSITE2VALUE = Get-VpnS2SInterface -Name $using:Site2Name -ErrorAction 0"
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value '}'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value 'IF ($VPNINTSITE1 -eq $null){'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value "Add-VpnS2SInterface -Protocol IKEv2 -AuthenticationMethod PSKOnly -NumberOfTries 3 -ResponderAuthenticationMethod PSKOnly -Name $using:Site1Name -Destination $using:Site1RemoteGatewayIP -IPv4Subnet $Site1IPv4 -SharedSecret $using:SharedKey"
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value '}'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value 'IF ($VPNINTSITE2 -eq $null){'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value "Add-VpnS2SInterface -Protocol IKEv2 -AuthenticationMethod PSKOnly -NumberOfTries 3 -ResponderAuthenticationMethod PSKOnly -Name $using:Site2Name -Destination $using:Site2RemoteGatewayIP -IPv4Subnet $Site2IPv4 -SharedSecret $using:SharedKey"
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value '}'

            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[File]ConfigureRRASDirectory'
        }

        ScheduledTask CreateConfigureRRAS
        {
            TaskName            = 'Configure RRAS'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'Once'
            StartTime           = (Get-Date).AddMinutes(1)
            ActionArguments     = 'C:\ConfigureRRAS\SetupRRAS.ps1'
            Enable              = $true
            ExecuteAsCredential = $LocalCreds
            LogonType           = 'Password'
            DependsOn = '[Script]ConfigureRRAS'
        }

        Script AllowLegacy
        {
            SetScript =
            {
                # Allow Remote Copy
                $allowlegacy = get-itemproperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess\Parameters" -Name "ModernStackEnabled" -ErrorAction 0
                IF ($allowlegacy.ModernStackEnabled -ne 0) {New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess\Parameters\" -Name "ModernStackEnabled" -Value 0 -Force}
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[ScheduledTask]CreateConfigureRRAS'
        }

    }
}