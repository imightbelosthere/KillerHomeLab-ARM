configuration GRANTCLUSTER
{
   param
   (
        [String]$SQLClusterName,
        [String]$BaseDN,
        [String]$NetBiosDomain,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        Script GrantClusterComputerCreate
        {
            SetScript =
            {
                Import-Module ActiveDirectory
                # Variables
                $SQLCLUST = "$using:SQLClusterName"
                $ComputerName = "$SQLCLUST"+'$'
                $acl = get-acl "ad:$using:BaseDN"
                $Computer = Get-ADComputer $ComputerName

                # The following object specific ACE is to grant Account permission to Create a Computer Objects
                $objectguid = new-object Guid bf967a86-0de6-11d0-a285-00aa003049e2 # is the rightsGuid for the extended right Create Computer Account
                $inheritedobjectguid = new-object Guid $Computer.ObjectGUID # is the schemaIDGuid for the user
                $identity = [System.Security.Principal.IdentityReference] $Computer.SID
                $adRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
                $type = [System.Security.AccessControl.AccessControlType] "Allow"
                $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
                $ace = new-object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$objectGuid,$inheritanceType,$inheritedobjectguid
                $acl.AddAccessRule($ace)
                Set-acl -aclobject $acl "ad:$using:BaseDN"

                # Variables
                $ServersDN = "OU=Servers,$using:BaseDN"
                $acl = get-acl "ad:$using:ServersDN"
                $ace = new-object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$objectGuid,$inheritanceType,$inheritedobjectguid
                $acl.AddAccessRule($ace)
                Set-acl -aclobject $acl "ad:$using:ServersDN"
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
        }

    }
}