configuration CREATEFILE
{
    Node localhost
    {
        Script TESTFILE
        {
            SetScript =
            {
                Set-Content -Path C:\TESTFOLDER\content.txt -Value "File created and populated correctly."
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }
    }
}