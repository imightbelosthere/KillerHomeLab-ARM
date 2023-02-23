configuration ROUTINGONLY
{
   param
   (
        [System.Management.Automation.PSCredential]$Admincreds                                  
    )

    Import-DscResource -Module ComputerManagementDsc # Used for Certificate Authority

    $ComputerName = $env:COMPUTERNAME
    [System.Management.Automation.PSCredential ]$LocalCreds = New-Object System.Management.Automation.PSCredential ("${ComputerName}\$($AdminCreds.UserName)", $AdminCreds.Password)

    Node localhost
    {
        File ConfigureRRAS
        {
            Type = 'Directory'
            DestinationPath = 'C:\ConfigureRRAS'
            Ensure = "Present"
        }

        Script RoutingOnly
        {
            SetScript =
            {
                # Create ConfigureRRAS Script
                Set-Content -Path C:\ConfigureRRAS\RoutingOnly.ps1 -Value "Install-RemoteAccess -VpnType RoutingOnly"
                Add-Content -Path C:\ConfigureRRAS\RoutingOnly.ps1 -Value "Import-Module RemoteAccess"
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[File]ConfigureRRAS'
        }

        ScheduledTask CreateConfigureRRAS
        {
            TaskName            = 'Routing Only'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'Once'
            StartTime           = (Get-Date).AddMinutes(1)
            ActionArguments     = 'C:\ConfigureRRAS\RoutingOnly.ps1'
            Enable              = $true
            ExecuteAsCredential = $LocalCreds
            LogonType           = 'Password'
            DependsOn = '[Script]RoutingOnly'
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