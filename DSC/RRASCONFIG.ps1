Configuration RRASCONFIG
{
   param
   (
        [String]$AZURENextHop,
        [String]$OutsideSubnetPrefix,
        [String]$InsideSubnetPrefix,
        [String]$AZUREVNet
    )

    Node localhost
    {   
        WindowsFeature Routing
        { 
            Ensure = 'Present' 
            Name = 'Routing' 
        }         

        WindowsFeature RSAT-RemoteAccess
        { 
            Ensure = 'Present' 
            Name = 'RSAT-RemoteAccess' 
            DependsOn = '[WindowsFeature]Routing'
        }

       Script AddStaticRoutes
        {
            SetScript =
            {
                $AZURERouteCheck = Get-NetRoute | Where-Object {$_.NextHop -like "$using:AZURENextHop"}
                IF ($AZURERouteCheck -eq $Null) {
                    $OutsideAdapter = Get-NetIPAddress | Where-Object {$_.IPAddress -like "$using:OutsideSubnetPrefix"+"*"}
                    New-NetRoute -DestinationPrefix "$using:AZUREVNet" -InterfaceIndex $OutsideAdapter.InterfaceIndex -NextHop "$using:AZURENextHop"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }
     }
  }