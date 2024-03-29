﻿configuration INSTALLWFC
{
    Node localhost
    {
       Script AllowLBProbe
        {
            SetScript =
            {
                $firewall = Get-NetFirewallRule "Azure LB Probe" -ErrorAction 0
                IF ($firewall -eq $null) {New-NetFirewallRule -DisplayName "Azure LB Probe" -Direction Inbound -LocalPort 1433,59999,5022 -Protocol TCP -Action Allow}
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

        
        WindowsFeature RSAT-Clustering-Mgmt
        {
            Ensure = 'Present'
            Name = 'RSAT-Clustering-Mgmt'
        }

        WindowsFeature RSAT-Clustering-PowerShell
        {
            Ensure = 'Present'
            Name = 'RSAT-Clustering-PowerShell'
        }

        WindowsFeature RSAT-Clustering-CmdInterface
        {
            Ensure = 'Present'
            Name = 'RSAT-Clustering-CmdInterface'
        }

        WindowsFeature Failover-Clustering
        {
            Ensure = 'Present'
            Name = 'Failover-Clustering'
        }
    }
}