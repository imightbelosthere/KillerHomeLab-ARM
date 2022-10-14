# Deploy-Secure-BastionHost
<img src="./x_Images/SecureBastionHost.svg" height="600" width="800"/>

This Deployment deploys the following items:

- 1 - Bastion Host
- 1 - Network Security Group

The deployment leverages Desired State Configuration scripts to further customize the following:


All Virtual Machines can be accessed via the [Bastion Host](https://docs.microsoft.com/en-us/azure/bastion/bastion-overview) that was deployed by using the Username and Password provided during depoyment.  The password can be manually entered or retrieved from the KeyVault that is creatd during deployment.

If you can't remember the Password used during deployment it is also written to an Encrypted Secret within the deployed KeyVault and can be retrieved as shown below:

<img src="./x_Images/DeploymentPassword.png" width="600"/>

If you can't remember the Username review the Deployment Input tab within your Resources Groups Deployment
<img src="./x_Images/DeploymentUsername.png" width="300"/>

Parameters that support changes
- VNetName.  Virtual Network Name
- AzureBastionSubnetPrefix.  Azure Bastion Subnet Prefix (Example:  10.1.1.253.0/24).
- SourceIPRange.  Source Public IP or Public IP Range (Example:  172.16.21.100 or 172.16.21.100-200)