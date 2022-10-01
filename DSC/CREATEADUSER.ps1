configuration CREATEADUSER
{
   param
   (
        [String]$NetBiosDomain,
        [String]$DomainName,        
        [String]$BaseDN,
        [String]$Account,        
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module ActiveDirectoryDsc

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    $UserExists = Get-ADUser -Filter * | Where-Object {$_.Name -like $Account}

    Node localhost
    {
        if ($UserExists -eq $null){
        ADUser CreateAccount
            {
                Ensure     = 'Present'
                UserName   = $Account
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