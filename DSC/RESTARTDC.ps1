configuration RESTARTDC
{
   param
   (
        [String]$Identifier
    )

    Import-DscResource -Module ComputerManagementDsc # Used for Reboots

    Node localhost
    {
        LocalConfigurationManager 
        {
           RebootNodeIfNeeded = $true
        }

        PendingReboot Reboot
        {
           Name = "Reboot"
        }

        Script Reboot
        {
            TestScript = {
            return (Test-Path "HKLM:\SOFTWARE\MyMainKey\$using:Identifier")
            }
            SetScript = {
			        New-Item -Path "HKLM:\SOFTWARE\MyMainKey\$using:Identifier" -Force
			        $global:DSCMachineStatus = 1 
                }
            GetScript = { return @{result = 'result'}}
        }
    }
}