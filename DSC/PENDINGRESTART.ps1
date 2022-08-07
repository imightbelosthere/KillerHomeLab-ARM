configuration PENDINGRESTART
{
   param
   (
    )

    Import-DscResource -Module ComputerManagementDsc # Used for Reboots

    Node localhost
    {
        PendingReboot Reboot
        {
           Name = "Reboot"
        }
    }
}