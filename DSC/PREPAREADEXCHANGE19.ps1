configuration PREPAREADEXCHANGE19
{
   param
   (
        [String]$ExchangeOrgName,
        [String]$ExchangeLicenseTerms,
        [String]$NetBiosDomain,
        [String]$DC1Name,
        [System.Management.Automation.PSCredential]$Admincreds
    )
    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile
    Import-DscResource -Module xStorage # Used by Disk

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        xMountImage MountExchangeISO
        {
            ImagePath   = 'S:\ExchangeInstall\Exchange2019.iso'
            DriveLetter = 'L'
        }

        xWaitForVolume WaitForISO
        {
            DriveLetter      = 'L'
            RetryIntervalSec = 5
            RetryCount       = 10
        }

        Script PrepareExchange2019AD
        {
            SetScript =
            {
                # Create Exchange AD Deployment
                (Get-ADDomainController -Filter *).Name | Foreach-Object { repadmin /syncall $_ (Get-ADDomain).DistinguishedName /AdeP }

                L:\Setup.exe /PrepareSchema /DomainController:"$using:dc1Name" $ExchangeLicenseTerms
                L:\Setup.exe /PrepareAD /on:"$using:ExchangeOrgName" /DomainController:"$using:dc1Name" $ExchangeLicenseTerms0000000000

                (Get-ADDomainController -Filter *).Name | Foreach-Object { repadmin /syncall $_ (Get-ADDomain).DistinguishedName /AdeP }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
            DependsOn = '[xWaitForVolume]WaitForISO'
        }
    }
}