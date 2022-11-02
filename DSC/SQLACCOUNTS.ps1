configuration SQLACCOUNTS
{
   param
   (
        [String]$NetBiosDomain,
        [String]$DomainName,        
        [String]$BaseDN,
        [String]$ServiceAccount,        
        [String]$InstallAccount,        
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module ActiveDirectoryDsc

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    $InstallAccountExists = Get-ADUser -Filter * | Where-Object {$_.Name -like $InstallAccount}
    $ServiceAccountExists = Get-ADUser -Filter * | Where-Object {$_.Name -like $ServiceAccount}

    Node localhost
    {
        if ($InstallAccount -eq $null){        
            ADUser Install
            {
                Ensure     = 'Present'
                UserName   = $InstallAccount
                DomainName = $DomainName
                Path       = "OU=Service,OU=Accounts,$BaseDN"
                Password = $DomainCreds
                Enabled = $True
            }
        }

        if ($ServiceAccount -eq $null){        
            ADUser SQLSvc1
            {
                Ensure     = 'Present'            
                UserName   = $ServiceAccount
                DomainName = $DomainName
                Path       = "OU=Service,OU=Accounts,$BaseDN"
                Password = $DomainCreds
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