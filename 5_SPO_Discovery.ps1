#Requires -RunAsAdministrator
#Requires -Version 5
#Requires -PSEdition Desktop

<#
	.SYNOPSIS
		Enumerates all Sites from a tenant.
	.DESCRIPTION
      	Enumerates all sites in the tenant including group connected, non-group connected, Team enabled, OneDrives that exist in a tenant.  Script first enumerates all sites, then individually enumerates to retreive properties not returned when using the limit parameter. Works on all tenant types.
	.EXAMPLE
	  	ProvisionOneDriveForBusiness -GroupMembers -GroupName "security group name"
	.EXAMPLE
	  	.\GetALLSites.ps1 -SPAdminCenterURL https://planetdemolab-admin.sharepoint.com
	.PARAMETER SPAdminCenterURL
	  	Full Url to the tenant SharePoint administration site Example: https://hostname-admin.sharepoint.com
	  
#>

[CmdletBinding()]
	Param(
		[Parameter(ParameterSetName='Default',Mandatory=$true,Position=0)]
			[string]$SPAdminCenterURL
        )

		Connect-SPOService -url $SPAdminCenterURL
		$ScriptDate = (get-Date).ToString("MM/dd/yyyy")

		$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
		$ALLSites = Get-SPOSite -limit all -IncludePersonalSite:$True
		$ALLSitesCount = $ALLSites.count
		$DataCollection = @()
		$i = 1
		foreach($Site in $ALLSites)
		{
			Write-host -ForegroundColor Yellow "Processing $($i) of $($ALLSitesCount)"
			if(($site.url -like "*/personal/*") -AND ($Site.url -like "*-my*") -AND ($Site.Template -like "SPSPERS*"))
			{
				#onedrive just write it out
				$Data = New-Object System.Object
				$Data | Add-Member -MemberType NoteProperty -Name Url -Value $Site.Url
				$Data | Add-Member -MemberType NoteProperty -Name Owner -Value $Site.Owner
				$Data | Add-Member -MemberType NoteProperty -Name Title -Value $Site.Title
				$Data | Add-Member -MemberType NoteProperty -Name StorageUsageCurrent -Value $Site.StorageUsageCurrent
				$Data | Add-Member -MemberType NoteProperty -Name LocaleId -Value $Site.LocaleId
				$Data | Add-Member -MemberType NoteProperty -Name LockState -Value $Site.LockState
				$Data | Add-Member -MemberType NoteProperty -Name Template -Value $Site.Template
				$Data | Add-Member -MemberType NoteProperty -Name WebsCount -Value $Site.WebsCount
				$Data | Add-Member -MemberType NoteProperty -Name RelatedGroupID -Value '00000000-0000-0000-0000-000000000000'
				$Data | Add-Member -MemberType NoteProperty -Name GroupId -Value '00000000-0000-0000-0000-000000000000'
				$Data | Add-Member -MemberType NoteProperty -Name DenyAddAndCustomizePages -Value "Disabled"
				$Data | Add-Member -MemberType NoteProperty -Name PWAEnabled -Value "Disabled"
				$Data | Add-Member -MemberType NoteProperty -Name IsTeamsConnected -Value $null
				$Data | Add-Member -MemberType NoteProperty -Name IsTeamsChannelConnected -Value $null
				$Data | Add-Member -MemberType NoteProperty -Name TeamsChannelType -Value $null
				$Data | Add-Member -MemberType NoteProperty -Name LastContentModifiedDate -Value $Site.LastContentModifiedDate
				$Data | Add-Member -MemberType NoteProperty -Name ExportDate -Value $ScriptDate
				$DataCollection += $Data
			}else{
				#all other sites
				$CurrentSite = Get-SPOSite -Identity $Site.url
				$Data = New-Object System.Object
				$Data | Add-Member -MemberType NoteProperty -Name Url -Value $CurrentSite.url
				$Data | Add-Member -MemberType NoteProperty -Name Owner -Value $CurrentSite.Owner
				$Data | Add-Member -MemberType NoteProperty -Name Title -Value $CurrentSite.Title
				$Data | Add-Member -MemberType NoteProperty -Name StorageUsageCurrent -Value $CurrentSite.StorageUsageCurrent
				$Data | Add-Member -MemberType NoteProperty -Name LocaleId -Value $CurrentSite.LocaleId
				$Data | Add-Member -MemberType NoteProperty -Name LockState -Value $CurrentSite.LockState
				$Data | Add-Member -MemberType NoteProperty -Name Template -Value $CurrentSite.Template
				$Data | Add-Member -MemberType NoteProperty -Name WebsCount -Value $CurrentSite.WebsCount
				$Data | Add-Member -MemberType NoteProperty -Name RelatedGroupID -Value $CurrentSite.RelatedGroupID
				$Data | Add-Member -MemberType NoteProperty -Name GroupId -Value $CurrentSite.GroupId
				$Data | Add-Member -MemberType NoteProperty -Name DenyAddAndCustomizePages -Value $CurrentSite.DenyAddAndCustomizePages
				$Data | Add-Member -MemberType NoteProperty -Name PWAEnabled -Value $CurrentSite.PWAEnabled
				$Data | Add-Member -MemberType NoteProperty -Name IsTeamsConnected -Value $CurrentSite.IsTeamsConnected
				$Data | Add-Member -MemberType NoteProperty -Name IsTeamsChannelConnected -Value $CurrentSite.IsTeamsChannelConnected
				$Data | Add-Member -MemberType NoteProperty -Name TeamsChannelType -Value $CurrentSite.TeamsChannelType
				$Data | Add-Member -MemberType NoteProperty -Name LastContentModifiedDate -Value $CurrentSite.LastContentModifiedDate
				$Data | Add-Member -MemberType NoteProperty -Name ExportDate -Value $ScriptDate
				$DataCollection += $Data
			}
			$i++
			$CurrentSite = $null
		}
		$DataCollection | Export-csv "C:\temp\spositessource.csv" -notypeinformation

#Stop Timer
$stopwatch.Stop()

#wrap up
write-host -ForegroundColor Yellow "Completed getting all site information for $($DataCollection.count) site(s) in  $([Math]::Ceiling($stopwatch.Elapsed.TotalMinutes)) minute(s)"
write-host -ForegroundColor Yellow "Saved output to C:\temp\05_SPO_Sourcespositessource.csv"



