Configuration RRAS
{
   param
   (
        [String]$Site1NextHop,
        [String]$Site2NextHop,
        [String]$SpokeNextHop,
        [String]$OutsideSubnetPrefix,
        [String]$InsideSubnetPrefix,
        [String]$Site1VNet,
        [String]$Site2VNet,
        [String]$SpokeVNet
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
                $Site1RouteCheck = Get-NetRoute | Where-Object {$_.NextHop -like "$using:Site1NextHop"}
                IF ($Site1RouteCheck -eq $Null) {
                    $OutsideAdapter = Get-NetIPAddress | Where-Object {$_.IPAddress -like "$using:OutsideSubnetPrefix"+"*"}
                    New-NetRoute -DestinationPrefix "$using:Site1VNet" -InterfaceIndex $OutsideAdapter.InterfaceIndex -NextHop "$using:Site1NextHop"
                }

                $Site2RouteCheck = Get-NetRoute | Where-Object {$_.NextHop -like "$using:Site2NextHop"}
                IF ($Site2RouteCheck -eq $Null) {
                    $OutsideAdapter = Get-NetIPAddress | Where-Object {$_.IPAddress -like "$using:OutsideSubnetPrefix"+"*"}
                    New-NetRoute -DestinationPrefix "$using:Site2VNet" -InterfaceIndex $OutsideAdapter.InterfaceIndex -NextHop "$using:Site2NextHop"
                }

                $SpokeRouteCheck = Get-NetRoute | Where-Object {$_.NextHop -like "$using:SpokeNextHop"}
                IF ($SpokeRouteCheck -eq $Null) {
                    $InsideAdapter = Get-NetIPAddress | Where-Object {$_.IPAddress -like "$using:InsideSubnetPrefix"+"*"}
                    New-NetRoute -DestinationPrefix "$using:SpokeVNet" -InterfaceIndex $InsideAdapter.InterfaceIndex -NextHop "$using:SpokeNextHop"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }
     }
  }