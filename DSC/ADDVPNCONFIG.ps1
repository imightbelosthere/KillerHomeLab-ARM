configuration ADDVPNCONFIG
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
        Script ADDVPNConfig
        {
            SetScript =
            {
                # Create ConfigureRRAS Script
                $RemoteAccessValue = '$RemoteAccess'
                $InstallStatusValue = '$InstallStatus'
                $AZUREIPv4 = "$using:AZUREIPv4Subnet"+':100'

                Set-Content -Path C:\ConfigureRRAS\ADDVPNConfig.ps1 -Value '$RemoteAccess = Get-RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\ADDVPNConfig.ps1 -Value "Add-VpnS2SInterface -Protocol IKEv2 -AuthenticationMethod PSKOnly -NumberOfTries 3 -ResponderAuthenticationMethod PSKOnly -Name $using:AZUREName -Destination $using:AZURERemoteGatewayIP -IPv4Subnet $AZUREIPv4 -SharedSecret $using:SharedKey"
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

        ScheduledTask ADDVPNConfig
        {
            TaskName            = 'ADD VPN Config'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'Once'
            StartTime           = (Get-Date).AddMinutes(1)
            ActionArguments     = 'C:\ConfigureRRAS\ADDVPNConfig.ps1'
            Enable              = $true
            ExecuteAsCredential = $LocalCreds
            LogonType           = 'Password'
            DependsOn = '[Script]ADDVPNConfig'
        }
    }
}