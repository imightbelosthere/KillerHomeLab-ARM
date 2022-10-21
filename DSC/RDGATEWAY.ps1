configuration RDGATEWAY
{
   param
   (
        [String]$PFXCommonName,
        [String]$InternalDomainName,
        [String]$UsersGroup,
        [String]$ComputersGroup,
        [System.Management.Automation.PSCredential]$Admincreds
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

        Script ConfigureRDGateway
        {
            SetScript =
            { 
                $PFXCN = "$using:PFXCommonName"
                $cert = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like 'CN='+$PFXCN+'*'})

                Import-Module RemoteDesktopServices -ErrorAction SilentlyContinue
                Stop-Service TSGateway

                Set-Item RDS:\GatewayServer\SSLCertificate\Thumbprint -Value $cert.Thumbprint
                Start-Service TSGateway

                $CAP = Get-ChildItem -Path RDS:\GatewayServer\CAP -ErrorAction 0
                IF ($CAP -eq $Null){
                    New-Item -Path RDS:\GatewayServer\CAP -Name NewCAP -UserGroups "$using:UsersGroup@$using:InternalDomainName" -AuthMethod 3
                }

                $RAP = Get-ChildItem -Path RDS:\GatewayServer\RAP -ErrorAction 0
                IF ($RAP.Name -eq $Null){
                    New-Item -Path RDS:\GatewayServer\RAP -Name NewRAP -UserGroups "$using:UsersGroup@$using:InternalDomainName" -ComputerGroupType 1 -ComputerGroup "$using:ComputersGroup@$using:InternalDomainName"
                }

            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $Admincreds
        }
    }
}