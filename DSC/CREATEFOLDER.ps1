configuration CREATEFOLDER
{
    Node localhost
    {
        File TESTFOLDER
        {
            Type = 'Directory'
            DestinationPath = 'C:\TESTFOLDER'
            Ensure = "Present"
        }
    }
}