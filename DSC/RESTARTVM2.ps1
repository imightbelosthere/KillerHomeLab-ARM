configuration RESTARTVM2
{
   param
   (
        [String]$Identifier
    )

    Node localhost
    {
        Script Reboot
        {
            SetScript = 
            {
                    $RegEntry = Get-Item -Path "HKLM:\SOFTWARE\MyMainKey\$using:Identifier" -ErrorAction 0
                    IF ($RegEntry -eq $null){
                        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WindowsAzureGuestAgent' -Name DependOnService -Type MultiString -Value Dnscache
			            New-Item -Path "HKLM:\SOFTWARE\MyMainKey\$using:Identifier" -Force
                        Restart-Computer -Force
                    } 
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }
    }
}