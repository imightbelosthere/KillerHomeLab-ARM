configuration MODVPNCONFIG
{
   param
   (
        [String]$AZUREIPv4Subnet,
        [String]$AZURETRANSITIPv4Subnet,
        [System.Management.Automation.PSCredential]$Admincreds                                  
    )

    $ComputerName = $env:COMPUTERNAME
    [System.Management.Automation.PSCredential ]$LocalCreds = New-Object System.Management.Automation.PSCredential ("${ComputerName}\$($AdminCreds.UserName)", $AdminCreds.Password)

    Import-DscResource -Module ComputerManagementDsc # Used for Scheduled Task

    Node localhost
    {
        Script MODVPNConfig
        {
            SetScript =
            {
                # Create ConfigureRRAS Script
                $RemoteAccessValue = '$RemoteAccess'
                $AZUREIPv4 = "$using:AZUREIPv4Subnet"+':100'
                $AZURETRANSITIPv4 = "$using:AZURETRANSITIPv4Subnet"+':100'
                $IPV4Subnet = '@("' + $AZUREIPv4 + '","' + $AZURETRANSITIPv4 + '")'

                Set-Content -Path C:\ConfigureRRAS\MODVPNConfig.ps1 -Value '$RemoteAccess = Get-RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\MODVPNConfig.ps1 -Value "Get-VpnS2SInterface | Set-VpnS2SInterface -IPv4Subnet $IPV4Subnet"
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

        ScheduledTask MODVPNConfig
        {
            TaskName            = 'VPN Config'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'Once'
            StartTime           = (Get-Date).AddMinutes(1)
            ActionArguments     = 'C:\ConfigureRRAS\MODVPNConfig.ps1'
            Enable              = $true
            ExecuteAsCredential = $LocalCreds
            LogonType           = 'Password'
            DependsOn = '[Script]MODVPNConfig'
        }
    }
}