configuration RDGATEWAY
{
   param
   (
        [String]$PFXCommonName,
        [String]$InternalDomainName,
        [String]$DomainUsersGroup,
        [String]$ComputersGroup,
        [System.Management.Automation.PSCredential]$Admincreds
    )

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

                $DomainMemberShip = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
                IF ($DomainMemberShip -eq 'True'){
                    $DomainCAP = Get-ChildItem -Path RDS:\GatewayServer\CAP -ErrorAction 0
                    IF ($DomainCAP -eq $Null){
                        New-Item -Path RDS:\GatewayServer\CAP -Name NewCAP -UserGroups "$using:UsersGroup@$using:InternalDomainName" -AuthMethod 3
                    }

                    $DomainRAP = Get-ChildItem -Path RDS:\GatewayServer\RAP -ErrorAction 0
                    IF ($DomainRAP.Name -eq $Null){
                        New-Item -Path RDS:\GatewayServer\RAP -Name NewRAP -UserGroups "$using:UsersGroup@$using:InternalDomainName" -ComputerGroupType 1 -ComputerGroup "$using:ComputersGroup@$using:InternalDomainName"
                    }
                }

                $WorkGroupMemberShip = (Get-WmiObject -Class Win32_ComputerSystem).Workgroup
                IF ($WorkGroupMemberShip -eq 'True'){
                    $WorkGrouopCAP = Get-ChildItem -Path RDS:\GatewayServer\CAP -ErrorAction 0
                    IF ($WorkGroupCAP -eq $Null){
                        New-Item -Path RDS:\GatewayServer\CAP -Name NewCAP -UserGroups "Administrators@BUILTIN" -AuthMethod 1
                    }

                    $WorkGroupRAP = Get-ChildItem -Path RDS:\GatewayServer\RAP -ErrorAction 0
                    IF ($WorkGroupRAP.Name -eq $Null){
                        New-Item -Path RDS:\GatewayServer\RAP -Name NewRAP -UserGroups "Administrators@BUILTIN" -ComputerGroupType 2
                    }
                }

            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $Admincreds
        }
    }
}