﻿configuration SYSPREP
{
    Node localhost
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = "StopConfiguration"
            ConfigurationMode = "ApplyOnly"
        }

        Script EnableTls12
        {
            SetScript =
            {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

        File RemovePantherDirectory
        {
            Ensure = "Absent"
            Type = "Directory"
            DestinationPath = "C:\Windows\Panther"
        }

        Script PrepareMachine
        {
            SetScript =
            {
                Start-Process "C:\Windows\System32\sysprep\sysprep.exe" -ArgumentList "/oobe /generalize /shutdown /quiet" -Wait
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[File]RemovePantherDirectory'
        }
    }
}