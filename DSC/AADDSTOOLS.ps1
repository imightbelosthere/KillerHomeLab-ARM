configuration AADDSTOOLS
{
    Node localhost
    {
        WindowsFeature RSATADDS
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
        }

        WindowsFeature RSATDNS
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
        }
    }
}