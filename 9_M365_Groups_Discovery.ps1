$Today = get-date -Format "MMddyyyy"
Connect-ExchangeOnline
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
$UnifiedGroups = Get-UnifiedGroup -Resultsize unlimited -IncludeAllProperties
$UnifiedGroupCount = $UnifiedGroups.count

$exportResultsCSV = "C:\temp\09_Unified_Groups_$today.csv"


$i=1
$DataCollection = @()
foreach($UnifiedGroup in $UnifiedGroups)
{
	Write-Host -ForegroundColor Yellow "Processing $($i) of $($UnifiedGroupCount)"
	
	if($UnifiedGroup.ResourceProvisioningOptions -eq "Team")
	{
		Write-Host -ForegroundColor Yellow "  skipping Team"
	}else{
		$Members = Get-UnifiedGroupLinks -Identity $UnifiedGroup.ExternalDirectoryObjectId -LinkType Members
        $MemberCount = $Members.Count
        $mi=1
		foreach($Member in $Members)
		{
            write-host -ForegroundColor Yellow "  Processing $($mi) of $($MemberCount)"
			$Data = New-Object System.Object
			$Data | Add-Member -MemberType NoteProperty -Name GroupDisplayName -Value $UnifiedGroup.DisplayName
			$Data | Add-Member -MemberType NoteProperty -Name GroupAlias -Value $UnifiedGroup.Alias
			$Data | Add-Member -MemberType NoteProperty -Name GroupExternalDirectoryObjectId -Value $UnifiedGroup.ExternalDirectoryObjectId
			$Data | Add-Member -MemberType NoteProperty -Name SharePointSiteUrl -Value $UnifiedGroup.SharePointSiteUrl
            $Data | Add-Member -MemberType NoteProperty -Name ResourceProvisioningOptions -Value $UnifiedGroup.ResourceProvisioningOptions
			$Data | Add-Member -MemberType NoteProperty -Name Useralias -Value $Member.Alias
			$Data | Add-Member -MemberType NoteProperty -Name UserExternalDirectoryObjectId -Value $Member.ExternalDirectoryObjectId
			$Data | Add-Member -MemberType NoteProperty -Name UserDisplayName -Value $Member.DisplayName
			$Data | Add-Member -MemberType NoteProperty -Name UserName -Value $Member.Name
			$Data | Add-Member -MemberType NoteProperty -Name UserWindowsLiveID -Value $Member.WindowsLiveID
			$Data | Add-Member -MemberType NoteProperty -Name Role -Value "Member"
			$DataCollection += $Data
            $mi++
		}
		
		$Owners = Get-UnifiedGroupLinks -Identity $UnifiedGroup.ExternalDirectoryObjectId -LinkType Owners
        $OwnerCount = $owners.count
        $oi=1
		foreach($Owner in $Owners)
		{
            write-host -ForegroundColor Yellow "  Processing Owners: $($oi) of $($OwnerCount)"
			$Data = New-Object System.Object
			$Data | Add-Member -MemberType NoteProperty -Name GroupDisplayName -Value $UnifiedGroup.DisplayName
			$Data | Add-Member -MemberType NoteProperty -Name GroupAlias -Value $UnifiedGroup.Alias
			$Data | Add-Member -MemberType NoteProperty -Name GroupExternalDirectoryObjectId -Value $UnifiedGroup.ExternalDirectoryObjectId
			$Data | Add-Member -MemberType NoteProperty -Name SharePointSiteUrl -Value $UnifiedGroup.SharePointSiteUrl
            $Data | Add-Member -MemberType NoteProperty -Name ResourceProvisioningOptions -Value $UnifiedGroup.ResourceProvisioningOptions
			$Data | Add-Member -MemberType NoteProperty -Name Useralias -Value $Owner.Alias
			$Data | Add-Member -MemberType NoteProperty -Name UserExternalDirectoryObjectId -Value $Owner.ExternalDirectoryObjectId
			$Data | Add-Member -MemberType NoteProperty -Name UserDisplayName -Value $Owner.DisplayName
			$Data | Add-Member -MemberType NoteProperty -Name UserName -Value $Owner.Name
			$Data | Add-Member -MemberType NoteProperty -Name UserWindowsLiveID -Value $Owner.WindowsLiveID
			$Data | Add-Member -MemberType NoteProperty -Name Role -Value "Owner"
			$DataCollection += $Data
            $oi++
		}
	}
	$i++
}

$DataCollection | Export-Csv $exportResultsCSV  -NoTypeInformation

#Stop Timer
$stopwatch.Stop()

#wrap up
write-host -ForegroundColor Yellow "Completed Processing $($DataCollection.count) users in $([Math]::Ceiling($stopwatch.Elapsed.TotalMinutes)) minute(s)"

write-host -ForegroundColor Yellow "Saved output to $exportResultsCSV"




