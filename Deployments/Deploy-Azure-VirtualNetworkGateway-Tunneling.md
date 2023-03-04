# AZHB1 Virtual Network Gateway Tunneling Add-On
<img src="./x_Images/AZHB1VirtualNetworkGateway-Tunneling.svg" height="600" width="800"/>

This Deployment deploys the following items:

- 1 - Resource Group
- 1 - Virtual Networks
- 1 - Virtual Network Peering
- 1 - Virtual Machine (AZSK1)
- 1 - Route Table

The deployment leverages Desired State Configuration scripts to further customize the following:


All Virtual Machines can be accessed via the [Bastion Host](https://docs.microsoft.com/en-us/azure/bastion/bastion-overview) that was deployed by using the Username and Password provided during depoyment.  The password can be manually entered or retrieved from the KeyVault that is creatd during deployment.

If you can't remember the Password used during deployment it is also written to an Encrypted Secret within the deployed KeyVault and can be retrieved as shown below:

<img src="./x_Images/DeploymentPassword.png" width="600"/>

If you can't remember the Username review the Deployment Input tab within your Resources Groups Deployment
<img src="./x_Images/DeploymentUsername.png" width="300"/>

Parameters that support changes
- AZHB1Region.  Location for AZHB1 Resources.
- ONPREMRegion.  Location for On-Premise Resources.
- ONPREMRG.  Resource Group for ONPrem Resources.
- TimeZone.  Select an appropriate Time Zone.
- AutoShutdownEnabled.  Yes = AutoShutdown Enabled, No = AutoShutdown Disabled.
- AutoShutdownTime.  24-Hour Clock Time for Auto-Shutdown (Example: 1900 = 7PM)
- AutoShutdownEmail.  Auto-Shutdown notification Email (Example:  user@domain.com)
- Admin Username.  Enter a valid Admin Username
- Admin Password.  Enter a valid Admin Password
- Azure UserObject ID.  Object ID for the AZHB1 Using running the deployment
- WindowsServerLicenseType.  Choose Windows Server License Type (Example:  Windows_Server or None)
- WindowsClientLicenseType.  Choose Windows Client License Type (Example:  Windows_Client or None)
- ONPREMNamingConvention. Enter a name that will be used as a naming prefix for (On-Prem Servers, VNets, etc) you are using.
- AZHB1NamingConvention. Enter a name that will be used as a naming prefix for (AZHB1 Servers, VNets, etc) you are using.
- ONPREMVNetID.  Enter first 2 octets of your desired Address Space for OnPrem Virtual Network(Example:  192.168)
- AZHB1VNetID.  Enter first 2 octets of your desired Address Space for AZHB1 Virtual Network(Example:  172.16)
- NVAOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Network Virtual Apliance 1 OS Sku
- ONPREMVMOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Hub VM 1 OS Sku
- AZHB1VMOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) AZHB1 VM 1 OS Sku
- NVAVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- ONPREMVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- AZHB1VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.