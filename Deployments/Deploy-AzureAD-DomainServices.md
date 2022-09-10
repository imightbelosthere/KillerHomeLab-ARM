# Deploy Azure AD Domain Services
<img src="./x_Images/AzureADDomainServices.svg" height="600" width="800"/>

This Deployment deploys the following items:

- 1 - Virtual Network
- 1 - Network Security Group
- 1 - Azure AD Domain Services Instance

Parameters that support changes
- AzureADDomainServicesSku.  Select Standard, Enterprise or Premium Sku
- Azure UserObject ID.  Object ID for the Azure Using running the deployment
- Azure UserName.  Existing User name of Managed Azure Account with "AD DC Administrators" rights
- Azure User Password.  Existing Password for Managed Azure Account with "AD DC Administrators" rights.
- Managed Domain Name.  Managed Azure Domain (Example:  killerhomelab.onmicrosoft.com or killerhomelab.onmicrosoft.us)
- Azure AD Domain Services Domain.  Choosen name for Azure Active Directory Services Domain Services Name (Example:  killerhomelab.com)
- WindowsServerLicenseType.  Choose Windows Server License Type (Example:  Windows_Server or None)
- Naming Convention. Enter a name that will be used as a naming prefix for (Servers, VNets, etc) you are using.
- Vnet1ID.  Enter first 2 octets of your desired Address Space for Virtual Network 1 (Example:  10.1)