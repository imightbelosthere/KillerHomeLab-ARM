configuration VPNCONFIG
{
   param
   (
        [String]$ComputerName,
        [String]$AZUREName,
        [String]$AZURERemoteGatewayIP,
        [String]$AZUREIPv4Subnet,
        [String]$OutsideSubnetPrefix,
        [String]$SharedKey,
        [System.Management.Automation.PSCredential]$Admincreds                                  
    )

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
                $AZUREIPv4 = "$using:AZUREIPv4Subnet"+':100'

                # Create Credentials
                $Load = "$using:LocalCreds"
                $Username = $LocalCreds.GetNetworkCredential().Username
                $Password = $LocalCreds.GetNetworkCredential().Password

                Set-Content -Path C:\ConfigureRRAS\ConfigRRAS.ps1 -Value '$RemoteAccess = Get-RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\ConfigRRAS.ps1 -Value "IF ($RemoteAccessValue.VpnS2SStatus -ne 'Installed'){"
                Add-Content -Path C:\ConfigureRRAS\ConfigRRAS.ps1 -Value 'Restart-Service -Name RemoteAccess -ErrorAction 0'
                Add-Content -Path C:\ConfigureRRAS\ConfigRRAS.ps1 -Value 'Install-RemoteAccess -VpnType VpnS2S'
                Add-Content -Path C:\ConfigureRRAS\ConfigRRAS.ps1 -Value 'Import-Module RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\ConfigRRAS.ps1 -Value '$RemoteAccess = Get-RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\ConfigRRAS.ps1 -Value '$InstallStatus = $RemoteAccess.VpnS2SStatus'
                Add-Content -Path C:\ConfigureRRAS\ConfigRRAS.ps1 -Value "while (($InstallStatusValue -ne 'Installed')){Start-Sleep 30}"
                Add-Content -Path C:\ConfigureRRAS\ConfigRRAS.ps1 -Value "Add-VpnS2SInterface -Protocol IKEv2 -AuthenticationMethod PSKOnly -NumberOfTries 3 -ResponderAuthenticationMethod PSKOnly -Name $using:AZUREName -Destination $using:AZURERemoteGatewayIP -IPv4Subnet $AZUREIPv4 -SharedSecret $using:SharedKey"
                Add-Content -Path C:\ConfigureRRAS\ConfigRRAS.ps1 -Value '}'

                # Create Scheduled Task
                $scheduledtask = Get-ScheduledTask "Configure RRAS" -ErrorAction 0
                IF ($scheduledtask -eq $null){
                    $action = New-ScheduledTaskAction -Execute Powershell -Argument '.\ConfigRRAS.ps1' -WorkingDirectory 'C:\ConfigureRRAS'
                    Register-ScheduledTask -Action $action -TaskName "Configure RRAS" -Description "Configure RRAS" -User $Username -Password $Password
                    Start-ScheduledTask -TaskName "Configure RRAS"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[File]ConfigureRRASDirectory'
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
            DependsOn = '[Script]ConfigureRRAS'
        }
    }
}