configuration RDGATEWAY
{
   param
   (
        [String]$RDGatewayServerFQDN,
        [String]$RDGatewayExternalFQDN
    )

    Import-DscResource -ModuleName xRemoteDesktopSessionHost

    Node localhost
    {   
        WindowsFeature RDS-Gateway
        {
            Name = "RDS-Gateway"
            Ensure = "Present"
        }

        WindowsFeature RSAT-RDS-Gateway
        {
            Name = "RSAT-RDS-Gateway"
            Ensure = "Present"
        }

        xRDGatewayConfiguration MyGateway {
            ConnectionBroker = $RDGatewayServerFQDN
            GatewayServer = $RDGatewayServerFQDN
            GatewayMode = 'Automatic'
            ExternalFqdn = $RDGatewayExternalFQDN
            LogonMethod = 'AllowUserToSelectDuringConnection'
            UseCachedCredentials = $false
            BypassLocal = $false
        }
    }
}