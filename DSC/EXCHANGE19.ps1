configuration EXCHANGE19
{
   param
   (
        [String]$ExchangeLicenseTerms,
        [String]$NetBiosDomain,
        [String]$DBName,
        [String]$SetupDC,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        Script InstallExchange2019
        {
            SetScript =
            {
                $CreateCMD = Get-ChildItem -Path S:\ExchangeInstall\DeployExchange.cmd -ErrorAction 0
                IF ($CreateCMD -eq $null) {                 
                Set-Content -Path S:\ExchangeInstall\DeployExchange.cmd -Value "L:\Setup.exe $using:ExchangeLicenseTerms /Mode:Install /Role:Mailbox /DbFilePath:M:\$using:DBName\$using:DBName.edb /LogFolderPath:M:\$using:DBName /MdbName:$using:DBName /dc:$using:SetupDC"
                }

                $ExchangeExists = Get-ExchangeServer -ErrorAction 0
                IF ($ExchangeExists -eq $null) {                 
                S:\ExchangeInstall\DeployExchange.cmd
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
        }

    }
}