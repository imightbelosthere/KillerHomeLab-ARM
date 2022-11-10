configuration SQLACCOUNTS
{
   param
   (
        [String]$NetBiosDomain,
        [String]$DomainName,        
        [String]$BaseDN,
        [String]$ServiceAccount,        
        [String]$SQLAdminAccount,        
        [System.Management.Automation.PSCredential]$AdminCreds,
        [System.Management.Automation.PSCredential]$SQLAdminAccountCreds,
        [System.Management.Automation.PSCredential]$ServiceAccountCreds
    )

    Import-DscResource -Module ActiveDirectoryDsc

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    $SQLAdminAccountExists = Get-ADUser -Filter * | Where-Object {$_.Name -like $SQLAdminAccount}
    $ServiceAccountExists = Get-ADUser -Filter * | Where-Object {$_.Name -like $ServiceAccount}

    Node localhost
    {
        if ($SQLAdminAccountExists -eq $null){        
            ADUser SQLAdmin
            {
                Ensure     = 'Present'
                UserName   = $SQLAdminAccount
                DomainName = $DomainName
                Path       = "OU=Service,OU=Accounts,$BaseDN"
                Password = $SQLAdminAccountCreds
                Enabled = $True
            }

            Script GrantCreateComputerAccounts
            {
                SetScript =
                {
                    $acl = get-acl "ad:$using:BaseDN"
                    $User = Get-ADUser "$using:SQLAdminAccount"

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
                DependsOn = '[ADUser]SQLAdmin'
            }

        }

        if ($ServiceAccountExists -eq $null){        
            ADUser SQLSvc1
            {
                Ensure     = 'Present'            
                UserName   = $ServiceAccount
                DomainName = $DomainName
                Path       = "OU=Service,OU=Accounts,$BaseDN"
                Password = $ServiceAccountcreds
                Enabled = $True
            }
        }
    }
}

$configData = @{
                AllNodes = @(
                              @{
                                 NodeName = 'localhost';
                                 PSDscAllowPlainTextPassword = $true
                                    }
                    )
               }