# Deploy Azure Virtual Desktop for Azure Active Directory Add-On
<img src="./x_Images/AzureVirtualDesktopAddOn.svg" height="600" width="800"/>

This Deployment deploys the following items:

- 1 - Azure KeyVault with Secret contianing Deployment Password

All Virtual Machines can be accessed via the [Bastion Host](https://docs.microsoft.com/en-us/azure/bastion/bastion-overview) that was deployed by using the Username and Password provided during depoyment.  The password can be manually entered or retrieved from the KeyVault that is creatd during deployment.

If you can't remember the Password used during deployment it is also written to an Encrypted Secret within the deployed KeyVault and can be retrieved as shown below:

<img src="./x_Images/DeploymentPassword.png" width="600"/>

If you can't remember the Username review the Deployment Input tab within your Resources Groups Deployment
<img src="./x_Images/DeploymentUsername.png" width="300"/>

Parameters that support changes
- TimeZone.  Select an appropriate Time Zone.
- HostPoolType.  Set this parameter to Personal if you would like to enable Persistent Desktop experience. Defaults to false.
- personalDesktopAssignmentType.  
- maxSessionLimit.  Maximum number of sessions.
- loadBalancerType.  Type of load balancer algorithm.
- validationEnvironment.  Whether to use validation enviroment.
- VMDiskType.  The VM disk type for the VM: HDD or SSD. (StandardSSD_LRS, Premium_LRS or Standard_LRS.)
- VMNumberOfInstances.  How Many Session Hosts you will need. (Example:  2)
- VMInitialNumber.  Starting number for Session Host Numeric's portion of Name. (Example: 0)
- availabilitySetUpdateDomainCount. The platform update domain count of avaiability set to be created.
- availabilitySetFaultDomainCount. The platform fault domain count of avaiability set to be created.
- Admin Username.  Enter a valid Admin Username
- Admin Password.  Enter a valid Admin Password
- Azure UserObject ID.  Object ID for the Azure Using running the deployment
- WVDGroupObjectID.  Object ID of Azure AD Group to Grant Azure Virtual Desktop Access To.
- WindowsClientLicenseType.  Choose Windows Client License Type (Example:  Windows_Client or None)
- Naming Convention. Enter a name that will be used as a naming prefix for (Servers, VNets, etc) you are using.
- SHOSSku.  Select win11-21h2-avd-m365 or win10-21h2-avd-m365 Session Host OS Sku