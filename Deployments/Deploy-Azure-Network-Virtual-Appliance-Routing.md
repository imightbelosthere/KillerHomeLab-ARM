# Azure Virtual Network Appliance Routing
<img src="./x_Images/xxx.svg" height="600" width="800"/>

This Deployment deploys the following items:

- 4 - Resource Groups
- 4 - Virtual Networks
- 4 - Virtual Machines (1-Hub, 1-Spoke, 1-Region1, 1-Region2)
- 1 - Standalone SQL Server
- 1 - Bastion Hosts
- 1 - Windows Router (VM with 2 NIC's)
- 4 - Route Tables
- 1 - Azure KeyVault with Secret contianing Deployment Password

The deployment leverages Desired State Configuration scripts to further customize the following:


All Virtual Machines can be accessed via the [Bastion Host](https://docs.microsoft.com/en-us/azure/bastion/bastion-overview) that was deployed by using the Username and Password provided during depoyment.  The password can be manually entered or retrieved from the KeyVault that is creatd during deployment.

If you can't remember the Password used during deployment it is also written to an Encrypted Secret within the deployed KeyVault and can be retrieved as shown below:

<img src="./x_Images/DeploymentPassword.png" width="600"/>

If you can't remember the Username review the Deployment Input tab within your Resources Groups Deployment
<img src="./x_Images/DeploymentUsername.png" width="300"/>

Parameters that support changes
- HUBRG.  Resource Group for HUB Resources.
- SPKRegion.  Location for Spoke Resources.
- SPKRG.  Resource Group for Spoke Resources.
- SITE1Region.  Location for Site1 Resources.
- SITE1RG.  Resource Group for Site1 Resources.
- SITE2Region.  Location for Site2 Resources.
- SITE2RG.  Resource Group for Site2 Resources.
- TimeZone.  Select an appropriate Time Zone.
- SQLSASURL.  Enter a valid URL that points to the SQL 2019 or 2017 .ISO
- AutoShutdownEnabled.  Yes = AutoShutdown Enabled, No = AutoShutdown Disabled.
- AutoShutdownTime.  24-Hour Clock Time for Auto-Shutdown (Example: 1900 = 7PM)
- AutoShutdownEmail.  Auto-Shutdown notification Email (Example:  user@domain.com)
- Admin Username.  Enter a valid Admin Username
- Admin Password.  Enter a valid Admin Password
- Azure UserObject ID.  Object ID for the Azure Using running the deployment
- WindowsServerLicenseType.  Choose Windows Server License Type (Example:  Windows_Server or None)
- WindowsClientLicenseType.  Choose Windows Client License Type (Example:  Windows_Client or None)
- HUBNamingConvention. Enter a name that will be used as a naming prefix for (Hub Servers, VNets, etc) you are using.
- SPKNamingConvention. Enter a name that will be used as a naming prefix for (Spoke Servers, VNets, etc) you are using.
- SITE1NamingConvention. Enter a name that will be used as a naming prefix for (Site1 Servers, VNets, etc) you are using.
- SITE2NamingConvention. Enter a name that will be used as a naming prefix for (Site2 Servers, VNets, etc) you are using.
- Sub DNS Domain.  OPTIONALLY, enter a valid DNS Sub Domain. (Example:  sub1. or sub1.sub2.    This entry must end with a DOT )
- Sub DNS BaseDN.  OPTIONALLY, enter a valid DNS Sub Base DN. (Example:  DC=sub1, or DC=sub1,DC=sub2,    This entry must end with a COMMA )
- HUBVNetID.  Enter first 2 octets of your desired Address Space for Hub Virtual Network(Example:  172.16)
- SPKVNetID.  Enter first 2 octets of your desired Address Space for Spoke Virtual Network(Example:  172.17)
- REG1VNetID.  Enter first 2 octets of your desired Address Space for Region1 Virtual Network(Example:  10.1)
- REG2VNetID.  Enter first 2 octets of your desired Address Space for Region1 Virtual Network(Example:  10.2)
- NVAOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Network Virtual Apliance 1 OS Sku
- SQLOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) SQL Server OS Sku
- HUBVMOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Hub VM 1 OS Sku
- SITE1VMOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Site1 VM 1 OS Sku
- SITE2VMOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Site2 VM 1 OS Sku
- NVAVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- HUBVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- SQLVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- SITE1VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- SITE2VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.