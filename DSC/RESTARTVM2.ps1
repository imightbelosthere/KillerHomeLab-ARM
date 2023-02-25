configuration RESTARTVM2
{
   param
   (
        [String]$Identifier,
        [String]$DomainName,
        [System.Management.Automation.PSCredential]$Admincreds
    )
    
    $ComputerName = $env:COMPUTERNAME
    [System.Management.Automation.PSCredential ]$LocalCreds = New-Object System.Management.Automation.PSCredential ("${ComputerName}\$($AdminCreds.UserName)", $AdminCreds.Password)
    [System.Management.Automation.PSCredential ]$DomainCredsFQDN = New-Object System.Management.Automation.PSCredential ("$($Admincreds.UserName)@$($DomainName)", $Admincreds.Password)

    Import-DscResource -Module ComputerManagementDsc # Used for Reboots

    $DomainMembership = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ActionAfterReboot = "StopConfiguration"
            ConfigurationMode = "ApplyOnly"

        }

        if ($DomainMembership -eq 'False')
        {
            Script RebootNonDomain
            {
                TestScript = {
                return (Test-Path "HKLM:\SOFTWARE\MyMainKey\$using:Identifier")
                }
                SetScript = {
                        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WindowsAzureGuestAgent' -Name DependOnService -Type MultiString -Value Dnscache
			            New-Item -Path "HKLM:\SOFTWARE\MyMainKey\$using:Identifier" -Force
			            $global:DSCMachineStatus = 1 
                    }
                GetScript = { return @{result = 'result'}}
                Credential = $LocalCreds
            }

            PendingReboot RebootNonDomain
            {
               Name = "Reboot"
               DependsOn = '[Script]RebootNonDomain'
            }
        }

        else
        {
            Script RebootDomain
            {
                TestScript = {
                return (Test-Path "HKLM:\SOFTWARE\MyMainKey\$using:Identifier")
                }
                SetScript = {
                        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WindowsAzureGuestAgent' -Name DependOnService -Type MultiString -Value Dnscache
			            New-Item -Path "HKLM:\SOFTWARE\MyMainKey\$using:Identifier" -Force
			            $global:DSCMachineStatus = 1 
                    }
                GetScript = { return @{result = 'result'}}
                PsDscRunAsCredential = $DomainCredsFQDN
            }

            PendingReboot RebootDomain
            {
               Name = "Reboot"
               DependsOn = '[Script]RebootDomain'
            }
        }
    }
}