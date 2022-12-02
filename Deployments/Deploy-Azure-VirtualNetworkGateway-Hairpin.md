# Azure Virtual Network Gateway Hairpin
<img src="./x_Images/AzureVirtualNetworkGatewayHairpin.svg" height="600" width="800"/>

This Deployment deploys the following items:

- 3 - Resource Groups
- 3 - Virtual Networks
- 2 - Virtual Network Gateways
- 2 - Local Network Gateways
- 2 - Connections
- 3 - Virtual Machines (Site1, Site2, On-Prem)
- 1 - Bastion Hosts
- 1 - Windows Routing and Remote Access server (VM with 2 NIC's)
- 3 - Route Tables
- 1 - Azure KeyVault with Secret contianing Deployment Password

The deployment leverages Desired State Configuration scripts to further customize the following:


All Virtual Machines can be accessed via the [Bastion Host](https://docs.microsoft.com/en-us/azure/bastion/bastion-overview) that was deployed by using the Username and Password provided during depoyment.  The password can be manually entered or retrieved from the KeyVault that is creatd during deployment.

If you can't remember the Password used during deployment it is also written to an Encrypted Secret within the deployed KeyVault and can be retrieved as shown below:

<img src="./x_Images/DeploymentPassword.png" width="600"/>

If you can't remember the Username review the Deployment Input tab within your Resources Groups Deployment
<img src="./x_Images/DeploymentUsername.png" width="300"/>

Parameters that support changes
- ONPREMRG.  Resource Group for ONPrem Resources.
- SITE1Region.  Location for Site1 Resources.
- SITE1RG.  Resource Group for Site1 Resources.
- SITE2Region.  Location for Site2 Resources.
- SITE2RG.  Resource Group for Site2 Resources.
- TimeZone.  Select an appropriate Time Zone.
- AutoShutdownEnabled.  Yes = AutoShutdown Enabled, No = AutoShutdown Disabled.
- AutoShutdownTime.  24-Hour Clock Time for Auto-Shutdown (Example: 1900 = 7PM)
- AutoShutdownEmail.  Auto-Shutdown notification Email (Example:  user@domain.com)
- Admin Username.  Enter a valid Admin Username
- Admin Password.  Enter a valid Admin Password
- Azure UserObject ID.  Object ID for the Azure Using running the deployment
- WindowsServerLicenseType.  Choose Windows Server License Type (Example:  Windows_Server or None)
- WindowsClientLicenseType.  Choose Windows Client License Type (Example:  Windows_Client or None)
- ONPREMNamingConvention. Enter a name that will be used as a naming prefix for (On-Prem Servers, VNets, etc) you are using.
- SITE1NamingConvention. Enter a name that will be used as a naming prefix for (Site1 Servers, VNets, etc) you are using.
- SITE2NamingConvention. Enter a name that will be used as a naming prefix for (Site2 Servers, VNets, etc) you are using.
- ONPREMVNetID.  Enter first 2 octets of your desired Address Space for OnPrem Virtual Network(Example:  192.168)
- SITE1VNetID.  Enter first 2 octets of your desired Address Space for Site1 Virtual Network(Example:  172.16)
- SITE2VNetID.  Enter first 2 octets of your desired Address Space for Site2 Virtual Network(Example:  172.17)
- NVAOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Network Virtual Apliance 1 OS Sku
- ONPREMVMOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Hub VM 1 OS Sku
- SITE1VMOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Site1 VM 1 OS Sku
- SITE2VMOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Site2 VM 1 OS Sku
- NVAVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- ONPREMVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- SITE1VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- SITE2VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.