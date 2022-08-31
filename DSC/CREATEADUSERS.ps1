Configuration CREATEADUSERS
{
   param
   (
        [String]$UserCount,
        [String]$NamingConvention,        
        [String]$NetBiosDomain,
        [String]$DomainName,        
        [String]$OUPath,             
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module ActiveDirectoryDsc

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node $AllNodes.NodeName

{
        $Number = 0
        foreach($Item in 1..$UserCount)
        {
            $Number += 1
            $UserName = "$NamingConvention-User$Number"

            ADUser "CreateUser$Number"
            {
                Ensure     = 'Present'            
                UserName   = "$UserName"
                DomainName = $DomainName
                Path       = "$OUPath"
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