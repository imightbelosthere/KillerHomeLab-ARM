﻿configuration GRANTSQLINSTALL
{
   param
   (
        [String]$NetBiosDomain,
        [String]$BaseDN,
        [String]$InstallAccount,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module ActiveDirectoryDsc

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        Script GrantCreateComputerAccounts
        {
            SetScript =
            {
                $acl = get-acl "ad:$using:BaseDN"
                $User = Get-ADUser "$using:InstallAccount"

                # The following object specific ACE is to grant Group permission to change user password on all user objects under OU
                $objectguid = new-object Guid bf967a86-0de6-11d0-a285-00aa003049e2 # is the rightsGuid for the extended right Create Computer Account
                $inheritedobjectguid = new-object Guid $User.ObjectGUID # is the schemaIDGuid for the user
                $identity = [System.Security.Principal.IdentityReference] $User.SID
                $adRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
                $type = [System.Security.AccessControl.AccessControlType] "Allow"
                $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
                $ace = new-object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$objectGuid,$inheritanceType,$inheritedobjectguid
                $acl.AddAccessRule($ace)
                Set-acl -aclobject $acl "ad:$using:BaseDN"
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
        }

    }
}