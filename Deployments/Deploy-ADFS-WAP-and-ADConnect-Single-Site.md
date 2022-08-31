# Deploy-ADFS-WAP-and-ADConnect-Single-Site
<img src="./x_Images/ADFSSingleSite.svg" height="600" width="800"/>

THE FOLLOWING DEPLOYMENT(S) MUST ALREADY EXIST IN ORDER TO USE THIS DEPLOYMENT DUE TO ADFS USING SQL:

- Deploy-SQLServer-DomainJoined-to-Existing-VNet

ONE OF THE FOLLOWING DEPLOYMENT(S) MUST ALREADY EXIST IN ORDER TO USE THIS DEPLOYMENT TO GENERATE ADFS CERTIFICATES:

- Deploy-PKI-2Tier-CA-With-OCSP
- Deploy-PKI-Enterprise-CA-With-OCSP
- Deploy-Exchange2019-Single-Site-with-EnterprisePKI


**** THE PARAMETERS SPECIFIED FOR THIS ADD-ON LAB MUST MATCH THE PARAMETERS OF THE BASE LAB THAT IT WILL BE ADDED TO ****

This Deployment deploys the following items:

- 1 - Virtual Network
- 1 - Bastion Host
- 1 - AD Connect Server
- 1 - ADFS Server
- 1 - WAP Server
- 1 - Network Security Group
- 1 - Azure Public DNS Zone
- 1 - Azure KeyVault with Secret contianing Deployment Password

The deployment leverages Desired State Configuration scripts to further customize the following:

DNS
- Configure Internal DNS ADFS Records

AD Connect
- Download Lastest Version of AD Connect to AD Connect Server

ADFS
- Request/Receive ADFS SAN Certificate from Enterprise CA
- Copy Exchange Certificate (If ExchangeExists)
- Configure ADFS Server

WAP
- Copy AFS Certificates
- Import ADFS Certificates
- Copy Exchange Certificate (If ExchangeExists)
- Import Exchange Certificates (If ExchangeExists)
- Configure WAP Server
- Create WAP/ADFS Trust

All Virtual Machines can be accessed via the [Bastion Host](https://docs.microsoft.com/en-us/azure/bastion/bastion-overview) that was deployed by using the Username and Password provided during depoyment.  The password can be manually entered or retrieved from the KeyVault that is creatd during deployment.

If you can't remember the Password used during deployment it is also written to an Encrypted Secret within the deployed KeyVault and can be retrieved as shown below:

<img src="./x_Images/DeploymentPassword.png" width="600"/>

If you can't remember the Username review the Deployment Input tab within your Resources Groups Deployment
<img src="./x_Images/DeploymentUsername.png" width="300"/>

Parameters that support changes
- TimeZone.  Select an appropriate Time Zone.
- PKIDeploymentType.  Type of PKI Environment Previously Deployed.  Select (2-Tier-PKI or Enterprise-PKI)
- ExchangeExists.  Does Exchange exist in your current environment.  Select (Yes or No)
- ExchangeExistsVersion.  Version of Exchange if Exchange Esists in current Environment 20(19) or 20(16).  Select (19 or 16)
- SQLExists.  Deploy ADFS to existing SQL Instance.  Select (Yes or No)
- SQLHost.  Enter a SQL Server Name for ADFS to use (Example: KHL-SQL-01)
- AutoShutdownEnabled.  Yes = AutoShutdown Enabled, No = AutoShutdown Disabled.
- AutoShutdownTime.  24-Hour Clock Time for Auto-Shutdown (Example: 1900 = 7PM)
- AutoShutdownEmail.  Auto-Shutdown notification Email (Example:  user@domain.com)
- Admin Username.  Enter a valid Admin Username
- Admin Password.  Enter a valid Admin Password
- Azure UserObject ID.  Object ID for the Azure Using running the deployment
- WindowsServerLicenseType.  Choose Windows Server License Type (Example:  Windows_Server or None)
- AzureADConnectDownloadUrl.  Download location for Azure AD Connect.
- Naming Convention. Enter a name that will be used as a naming prefix for (Servers, VNets, etc) you are using.
- Sub DNS Domain.  OPTIONALLY, enter a valid DNS Sub Domain. (Example:  sub1. or sub1.sub2.    This entry must end with a DOT )
- Sub DNS BaseDN.  OPTIONALLY, enter a valid DNS Sub Base DN. (Example:  DC=sub1, or DC=sub1,DC=sub2,    This entry must end with a COMMA )
- Net Bios Domain.  Enter a valid Net Bios Domain Name (Example:  killerhomelab).
- Internal Domain.  Enter a valid Internal Domain (Exmaple:  killerhomelab)
- InternalTLD.  Select a valid Top-Level Domain using the Pull-Down Menu.
- External Domain.  Enter a valid External Domain (Exmaple:  killerhomelab)
- ExternalTLD.  Select a valid Top-Level Domain for your External Domain using the Pull-Down Menu.
- Root CA Name.  Enter a Name for your Root Certificate Authority
- Issuing CA Name.  Enter a Name for your Issuing Certificate Authority
- Vnet1ID.  Enter first 2 octets of your desired Address Space for Virtual Network 1 (Example:  10.1)
- ADCOSSku.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Azure AD Connect OS Sku
- WAPOSSku.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Web Application Proxy OS Sku
- ADFSOSSku.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Active Directory Federation Services OS Sku
- ADCVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- ADFS1VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- WAP1VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.