configuration RESTARTVMNDJ
{
   param
   (
        [String]$Identifier
    )

    Import-DscResource -Module xPendingReboot # Used for Reboots

    Node localhost
    {
        LocalConfigurationManager 
        {
           RebootNodeIfNeeded = $true
        }

        xPendingReboot Reboot
        {
           Name = "Reboot"
        }

        Script Reboot
        {
            TestScript = {
            return (Test-Path "HKLM:\SOFTWARE\MyMainKey\$using:Identifier")
            }
            SetScript = {
                    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WindowsAzureGuestAgent' -Name DependOnService -Type MultiString -Value Dnscache
			        New-Item -Path "HKLM:\SOFTWARE\MyMainKey\$using:Identifier" -Force
			        $global:DSCMachineStatus = 1 
                }
            GetScript = { return @{result = 'result'}}
        }
    }
}