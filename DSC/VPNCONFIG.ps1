configuration VPNCONFIG
{
   param
   (
        [String]$AZUREName,
        [String]$AZURERemoteGatewayIP,
        [String]$AZUREIPv4Subnet,
        [String]$OutsideSubnetPrefix,
        [String]$SharedKey,
        [System.Management.Automation.PSCredential]$Admincreds                                  
    )

    $ComputerName = $env:COMPUTERNAME
    [System.Management.Automation.PSCredential ]$LocalCreds = New-Object System.Management.Automation.PSCredential ("${ComputerName}\$($AdminCreds.UserName)", $AdminCreds.Password)

    Import-DscResource -Module ComputerManagementDsc # Used for Scheduled Task

    Node localhost
    {
        Script VPNConfig
        {
            SetScript =
            {
                # Create ConfigureRRAS Script
                $RemoteAccessValue = '$RemoteAccess'
                $InstallStatusValue = '$InstallStatus'
                $AZUREIPv4 = "$using:AZUREIPv4Subnet"+':100'

                Set-Content -Path C:\ConfigureRRAS\VPNConfig.ps1 -Value '$RemoteAccess = Get-RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\VPNConfig.ps1 -Value "IF ($RemoteAccessValue.VpnS2SStatus -ne 'Installed'){"
                Add-Content -Path C:\ConfigureRRAS\VPNConfig.ps1 -Value 'Restart-Service -Name RemoteAccess -ErrorAction 0'
                Add-Content -Path C:\ConfigureRRAS\VPNConfig.ps1 -Value 'Install-RemoteAccess -VpnType VpnS2S'
                Add-Content -Path C:\ConfigureRRAS\VPNConfig.ps1 -Value 'Import-Module RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\VPNConfig.ps1 -Value '$RemoteAccess = Get-RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\VPNConfig.ps1 -Value '$InstallStatus = $RemoteAccess.VpnS2SStatus'
                Add-Content -Path C:\ConfigureRRAS\VPNConfig.ps1 -Value "while (($InstallStatusValue -ne 'Installed')){Start-Sleep 30}"
                Add-Content -Path C:\ConfigureRRAS\VPNConfig.ps1 -Value "Add-VpnS2SInterface -Protocol IKEv2 -AuthenticationMethod PSKOnly -NumberOfTries 3 -ResponderAuthenticationMethod PSKOnly -Name $using:AZUREName -Destination $using:AZURERemoteGatewayIP -IPv4Subnet $AZUREIPv4 -SharedSecret $using:SharedKey"
                Add-Content -Path C:\ConfigureRRAS\VPNConfig.ps1 -Value '}'
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

        ScheduledTask CreateVPNConfig
        {
            TaskName            = 'VPN Config'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'Once'
            StartTime           = (Get-Date).AddMinutes(1)
            ActionArguments     = 'C:\ConfigureRRAS\VPNConfig.ps1'
            Enable              = $true
            ExecuteAsCredential = $LocalCreds
            LogonType           = 'Password'
            DependsOn = '[Script]VPNConfig'
        }

        Script ConfigureNAT
        {
            SetScript =
            {
                $OutsideAdapter = Get-NetIPAddress | Where-Object {$_.IPAddress -like "$using:OutsideSubnetPrefix"+"*"}
                netsh routing ip nat install
                netsh routing ip nat add interface $OutsideAdapter.InterfaceAlias
                netsh routing ip nat set interface $OutsideAdapter.InterfaceAlias mode=full
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[ScheduledTask]CreateVPNConfig'
        }
    }
}