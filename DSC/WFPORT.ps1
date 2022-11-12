Configuration WFPORT
{
   param
   (
        [String]$FirewallRuleName,
        [String]$Direction,
        [String]$Port,
        [String]$Protocol,
        [System.Management.Automation.PSCredential]$Admincreds
 
    )

    Import-DscResource -Module xNetworking # Used Firewall Rules
 
    Node localhost
    {
        xFirewall Firewall
        {
            Name                  = $FirewallRuleName
            DisplayName           = $FirewallRuleName
            Ensure                = 'Present'
            Enabled               = 'True'
            Profile               = ('Any')
            Direction             = $Direction
            RemotePort            = $Port
            LocalPort             = $Port
            Protocol              = $Protocol
            PsDscRunAsCredential = $Admincreds
        }
    }
  }