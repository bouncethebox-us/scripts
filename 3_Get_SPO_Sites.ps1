$Sites = Get-SPOSite
Foreach ($Site in $Sites)
{
Get-SPOSite -Limit All -Identity $Site.Url | Select Url, SensitivityLabel
}

$Sites | Export-Csv -Path "C:\temp\03_get_spo_sites.csv" -NoTypeInformation