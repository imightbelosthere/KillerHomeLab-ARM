configuration NEWPENDINGRESTART
{
   param
   (
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
    }
}