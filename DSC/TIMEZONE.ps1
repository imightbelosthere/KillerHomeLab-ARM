Configuration TIMEZONE
{
   param
   (
        [String]$TimeZone
    )

    Import-DscResource -Module ComputerManagementDsc

    Node LocalHost
    {

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZone
        }
    }
}