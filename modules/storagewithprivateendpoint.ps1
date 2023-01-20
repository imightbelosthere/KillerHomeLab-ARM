# Enter the Amount of Storage Accounts to Create
[uint16]$NumberOfStorageAccountInstances = Read-Host "Enter the number of Storage Accounts (1-9999) you would like to create (Example: 10)"

# Enter the Initial Number for Storage Account Naming
[uint16]$StorageAccountInitialNumber = Read-Host "Enter the Initial Number (1-9999) for Storage Account Naming (Example: 1)"

# Enter a Storage Account Prefix
$StorageAccountPrefix = Read-Host "Enter a Storage Account Prefix with a maximum of 20 characters (Example: namethatequals23char)?"

# Select Virtual Network and Subnet
$VirtualNetworks = Get-AzVirtualNetwork | Select-Object Name, Subnets, Id
$VirtualNetwork = $VirtualNetworks | Out-GridView -PassThru -Title "Please Select a Virtual Network for the Private Endpoints"
$PrivateEndpointVirtualNetworkName = $VirtualNetwork.Name
$subnets = $VirtualNetwork | Select -ExpandProperty subnets
$subnet = $subnets | Select-Object Name, Id | Out-GridView -PassThru -Title "Please Select a Subnet for the Private Endpoints"
$PrivateEndpointSubnetName = $subnet.Name

$parameters = @{  
    StorageAccountPrefix = $StorageAccountPrefix
    PrivateEndpointVnetName = $PrivateEndpointVirtualNetworkName
    PrivateEndpointSubnetName = $PrivateEndpointSubnetName
    NumberOfStorageAccountInstances = $NumberOfStorageAccountInstances
    StorageAccountInitialNumber = $StorageAccountInitialNumber
}

New-AzResourceGroupDeployment -Name "Deploy-$NumberOfStorageAccountInstances-StorageAccounts-with-PrivateEndpoints" -ResourceGroupName Storage-Account-Testing -TemplateFile C:\_DevOpsServer\JAIC-RDP-Solution\templates\storagewithprivateendpoint.bicep -TemplateParameterObject $parameters