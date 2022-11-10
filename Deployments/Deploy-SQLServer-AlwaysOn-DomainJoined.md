# SQL Server Always-On Domain-Joined using an Existing Subnet
<img src="./x_Images/xxx.svg" height="600" width="800"/>

This Deployment deploys the following items:

- 1 - Azure KeyVault with Secret contianing Deployment Password
- 1 - Domain Joined Tools Machine (Windows 11/10)
- 1 - Managed Availability Set
- 1 - Azure Load Balancer
- 2 - D8s_v3 Domain Joined VM's with SQL Server 2019 Datacenter on Windows Server 2022 Datacenter

The deployment leverages Desired State Configuration scripts to further customize the following:

- Create Active Directory SQL Service Accounts
- Configure SQL Aways On
- Installs SQL Management Studio on Tools Machine


All Virtual Machines can be accessed via the [Bastion Host](https://docs.microsoft.com/en-us/azure/bastion/bastion-overview) that was deployed by using the Username and Password provided during depoyment.  The password can be manually entered or retrieved from the KeyVault that is creatd during deployment.

If you can't remember the Password used during deployment it is also written to an Encrypted Secret within the deployed KeyVault and can be retrieved as shown below:

<img src="./x_Images/DeploymentPassword.png" width="600"/>

If you can't remember the Username review the Deployment Input tab within your Resources Groups Deployment
<img src="./x_Images/DeploymentUsername.png" width="300"/>

Parameters that support changes
- TimeZone.  Select an appropriate Time Zone.
- AutoShutdownEnabled.  Yes = AutoShutdown Enabled, No = AutoShutdown Disabled.
- AutoShutdownTime.  24-Hour Clock Time for Auto-Shutdown (Example: 1900 = 7PM)
- AutoShutdownEmail.  Auto-Shutdown notification Email (Example:  user@domain.com)
- Admin Username.  Enter a valid Admin Username
- Admin Password.  Enter a valid Admin Password
- ServiceAccount.  SQL Service Account Name
- SQLAdminAccount.  SQL Admin Account Name
- Azure UserObject ID.  Object ID for the Azure Using running the deployment
- WindowsServerLicenseType.  Choose Windows Server License Type (Example:  Windows_Server or None)
- WindowsClientLicenseType.  Choose Windows Client License Type (Example:  Windows_Client or None)
- SQLLicenseType.  SQL License Type.
- Naming Convention. Enter a name that will be used as a naming prefix for (Servers, VNets, etc) you are using.
- Sub DNS Domain.  OPTIONALLY, enter a valid DNS Sub Domain. (Example:  sub1. or sub1.sub2.    This entry must end with a DOT )
- Sub DNS BaseDN.  OPTIONALLY, enter a valid DNS Sub Base DN. (Example:  DC=sub1, or DC=sub1,DC=sub2,    This entry must end with a COMMA )
- Net Bios Domain.  Enter a valid Net Bios Domain Name (Example:  killerhomelab).
- Internal Domain.  Enter a valid Internal Domain (Exmaple:  killerhomelab)
- InternalTLD.  Select a valid Top-Level Domain using the Pull-Down Menu.
- Vnet1ID.  Enter first 2 octets of your desired Address Space for Virtual Network 1 (Example:  10.1)
- availabilitySetUpdateDomainCount.  Azure Update Domain Count.
- availabilitySetFaultDomainCount.  Azure Update Domain Count.
- SQLTOOLSOSSku.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016)
- SQL Tools VM OS Sku
- SQLTOOLSOSVersion.  The default is Latest however a specific OS Version can be entired based on the above OS Sku.
- SQLTOOLSVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.