configuration GRANTETS
{
   param
   (
        [String]$ExchangeSecurityGroup
    )

    Node localhost
    {
        Script IssueCARequest
        {
            SetScript =
            {
                Add-LocalGroupMember -Member "$using:ExchangeSecurityGroup" -Group Administrators
                Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled False
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

    }
}