configuration IIS
{
    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
        
        WindowsFeature Web-Mgmt-Console
        {
            Ensure = 'Present'
            Name = 'Web-Mgmt-Console'
        }
        
        WindowsFeature Web-Server
        {
            Ensure = 'Present'
            Name = 'Web-Server'
            IncludeAllSubFeature = $true
        }
    }
}