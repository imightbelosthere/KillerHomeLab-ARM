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
                $Site1IPv4 = "$using:Site1IPv4Subnet"+':100'
                $Site2IPv4 = "$using:Site2IPv4Subnet"+':100'

                # Create Credentials
                $Load = "$using:LocalCreds"
                $Username = $LocalCreds.GetNetworkCredential().Username
                $Password = $LocalCreds.GetNetworkCredential().Password

                Set-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value '$RemoteAccess = Get-RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value "IF ($RemoteAccessValue.VpnS2SStatus -ne 'Installed'){"
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value 'Restart-Service -Name RemoteAccess -ErrorAction 0'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value 'Install-RemoteAccess -VpnType VpnS2S'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value 'Import-Module RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value '$RemoteAccess = Get-RemoteAccess'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value '$InstallStatus = $RemoteAccess.VpnS2SStatus'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value "while (($InstallStatusValue -ne 'Installed')){sleep 30}"
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value 'Start-Sleep 30'
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value "Add-VpnS2SInterface -Protocol IKEv2 -AuthenticationMethod PSKOnly -NumberOfTries 3 -ResponderAuthenticationMethod PSKOnly -Name $using:Site1Name -Destination $using:Site1RemoteGatewayIP -IPv4Subnet $Site1IPv4 -SharedSecret $using:SharedKey"
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value "Add-VpnS2SInterface -Protocol IKEv2 -AuthenticationMethod PSKOnly -NumberOfTries 3 -ResponderAuthenticationMethod PSKOnly -Name $using:Site2Name -Destination $using:Site2RemoteGatewayIP -IPv4Subnet $Site2IPv4 -SharedSecret $using:SharedKey"
                Add-Content -Path C:\ConfigureRRAS\SetupRRAS.ps1 -Value '}'

                # Create Scheduled Task
                $scheduledtask = Get-ScheduledTask "Configure RRAS" -ErrorAction 0
                IF ($scheduledtask -eq $null){
                    $action = New-ScheduledTaskAction -Execute Powershell -Argument '.\SetupRRAS.ps1' -WorkingDirectory 'C:\ConfigureRRAS'
                    Register-ScheduledTask -Action $action -TaskName "Configure RRAS" -Description "Configure RRAS" -User $Username -Password $Password
                    Start-ScheduledTask "Configure RRAS"
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