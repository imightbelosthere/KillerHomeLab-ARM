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
        IF ($Direction -eq 'Inbound'){
            xFirewall Firewall
            {
                Name                  = $FirewallRuleName
                DisplayName           = $FirewallRuleName
                Ensure                = 'Present'
                Enabled               = 'True'
                Profile               = ('Any')
                Direction             = $Direction
                LocalPort             = $Port
                RemotePort            = ('Any')
                Protocol              = $Protocol
                PsDscRunAsCredential = $Admincreds
            }
        }

        IF ($Direction -eq 'Outbound'){
            xFirewall Firewall
            {
                Name                  = $FirewallRuleName
                DisplayName           = $FirewallRuleName
                Ensure                = 'Present'
                Enabled               = 'True'
                Profile               = ('Any')
                Direction             = $Direction
                LocalPort             = ('Any')
                RemotePort            = $Port
                Protocol              = $Protocol
                PsDscRunAsCredential = $Admincreds
            }
        }
    }
  }