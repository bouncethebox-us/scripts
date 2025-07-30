#This script requires the enterprise application deployed in Part02_Part02_EnumWebRoleAssignments.ps1

#This script enumerates all M365 groups that are not teams enabled, retrieves the last conversation (NOT accounting for replies) and last user content modified for the connected site.

#help

#https://learn.microsoft.com/en-us/graph/api/group-list?view=graph-rest-1.0&tabs=http
    #GroupMember.Read.All   #https://learn.microsoft.com/en-us/graph/permissions-reference
#add teams
    #Team.ReadBasic.All #https://learn.microsoft.com/en-us/graph/api/teams-list?view=graph-rest-1.0&tabs=http
#convos permissions
    #Group.Read.All but should use, but couldn't find Group-Conversation.Read.All    #https://learn.microsoft.com/en-us/graph/api/group-list-conversations?view=graph-rest-1.0&tabs=http

#need certificate too
#classic sharepoint sites.fullcontrol


$stopwatch =  [system.diagnostics.stopwatch]::StartNew()


#Replace 'X' with values from Part02 script Output
#Variables
#PlanetReporting
$CertThumbprint = 'XXXX'
$ApplicationID = 'XXXXXXXXX'
$TenantDomainName = 'XXXX.onmicrosoft.com'
$AppRegSecret = 'XXXXXXXXX'


function GetToken($GrantType,$clientID,$ClientSecret,$scope,$TokenURLPrefix,$TenantName)
{
    $ReqTokenBody = @{
        Grant_Type    = $GrantType
        client_Id     = $clientID
        Client_Secret = $ClientSecret
        Scope         = $scope
    } 

    $TokenResponse = Invoke-RestMethod -Uri "$TokenURLPrefix$TenantName/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody
    return $TokenResponse
}

function GetCurrentDateTime {
	param (
		[Parameter(ParameterSetName='Default',Mandatory=$false,Position=0)]
		[switch]$DateOnly
	)
	if($DateOnly){
		return (get-Date).ToString("MM/dd/yyyy")
	}else{
		return Get-Date
	}
}


function Convert-UTCtoLocal($Time)
{
    $UTCTime = (Get-Date $Time).ToUniversalTime()
    $strCurrentTimeZone = (Get-WmiObject win32_timezone).StandardName 
    $TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone) 
    $LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TZ)
    return $LocalTime
}

Function ParseStorageLocation($SPStorageLocation)
{
    try{
        $Seperator = '/Shared%20Documents'
        $WebURL = ($SPStorageLocation -split $Seperator)[0]
    }catch{
        $WebURL = $null
    }
    
    return $WebURL
}

Function GetGroupLastConversation($GraphURLPrefix,$GroupID,$token){
    try{
        $Conversations = $null
        $GraphUrl = "$GraphURLPrefix$GroupID/conversations"
        $GraphUrl

        $RestCall = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $GraphUrl -Method Get
        $Conversations += $RestCall.value

        while($restcall.'@odata.nextLink' -ne $null)
        {
            $RestCall = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $restcall.'@odata.nextLink'-Method Get
            $Conversations += $RestCall.value
        }
    }catch{
        $Conversations =  "Failed to Get Group Conversations:: $($_.Exception.Message)"
    }

    return $Conversations
}

Function GetGroupLastContentModified($GraphURLPrefix,$GroupID,$token,$TenantDomainName,$ApplicationID,$CertThumbprint)
{
    try{
        $StorageLocation = $null
        $GraphUrl = "$GraphURLPrefix$GroupID/drive"
        #$GraphUrl
        

        $RestCall = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $GraphUrl -Method Get
        $StorageLocation = ParseStorageLocation $RestCall.webUrl
        
        try{
            Connect-PnPOnline -Tenant $TenantDomainName -ClientId $ApplicationID -Thumbprint $CertThumbprint -Url $StorageLocation
            $ContentLastModifiedDate = Convert-UTCtoLocal ((get-pnplist 'Documents').LastItemUserModifiedDate)
        }catch{
            $ContentLastModifiedDate = "Content Last Modified failed: $($_.Exception.Message)"
        }

        if($RestCall.webUrl -notlike "https*")
        {
            $ContentLastModifiedDate = "No SharePoint file location"
        }
    }catch{
        $ContentLastModifiedDate =  "Failed to Get SharePoint location:: $($_.Exception.Message)"
    }

    return $ContentLastModifiedDate
}


#get Token
$ScriptDate = GetCurrentDateTime -DateOnly
$Token = (GetToken 'client_credentials' $ApplicationID $AppRegSecret 'https://graph.microsoft.com/.default' 'https://login.microsoftonline.com/' $TenantDomainName).access_token

#get all unified groups
write-host -ForegroundColor Yellow "Begin to enumerate M365Groups in tenant"
$UnifiedGroups = $null
$GraphUrl = "https://graph.microsoft.com/v1.0/groups?`$filter=groupTypes/any(c:c eq 'Unified')&`$select=displayName,id,mailNickname,securityEnabled,visibility,membershipRule"

$RestCall = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $GraphUrl -Method Get
$UnifiedGroups += $RestCall.value

while($restcall.'@odata.nextLink' -ne $null)
{
    $RestCall = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $restcall.'@odata.nextLink'-Method Get
    $UnifiedGroups += $RestCall.value
}
$UnifiedGroupsCount = $UnifiedGroups.count
write-host -ForegroundColor Green "Completed enumeration of M365Groups in tenant:: Discovered $($UnifiedGroupsCount)"

#get all the teams
write-host -ForegroundColor Yellow "Begin to enumerate Teams in tenant"
$Teams = $null
$GraphUrl = "https://graph.microsoft.com/v1.0/teams?`$select=id"

$RestCall = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $GraphUrl -Method Get
$Teams += $RestCall.value

while($restcall.'@odata.nextLink' -ne $null)
{
    $RestCall = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $restcall.'@odata.nextLink'-Method Get
    $Teams += $RestCall.value
}
$TeamsCount = $Teams.count

write-host -ForegroundColor Green "Completed enumeration of Teams in tenant:: Discovered $($TeamsCount)"

#get non team enabled M365 Groups
$FilteredUGroups = Compare-Object -ReferenceObject $UnifiedGroups -DifferenceObject $Teams -Property id -PassThru
$FilteredUGroupsCount = $FilteredUGroups.count
write-host -ForegroundColor Green "Filtered Teams from M365 Groups:: Filtered $($FilteredUGroupsCount)"


#iterate through each M365 Group
$UnifiedGroupDataCollection = @()
$i=1
    
foreach($UnifiedGroup in $FilteredUGroups)
{
    write-host -ForegroundColor Yellow "Processing Unified Groups: $($i) of $($FilteredUGroupsCount):: $($UnifiedGroup.displayName)"
    #get the conversations and get the most recent
    $Conversations = $null
    $Conversations = GetGroupLastConversation "https://graph.microsoft.com/v1.0/groups/" $UnifiedGroup.id $token


    #$LastTeamPost = Convert-UTCtoLocal (($PostDataCollection | Sort-Object -property lastModifiedDateTime -Descending)[0]).lastModifiedDateTime    if($Conversations.count -ge 1){
    if($Conversations -like "Failed to Get*")
    {
        $LastUnifiedGroupConversationDate = $Conversations
    }else{
        if($Conversations.count -ge 1){
            try{
                $LastUnifiedGroupConversationDate = Convert-UTCtoLocal ($Conversations | Sort-Object -Descending -Property lastDeliveredDateTime)[0].lastDeliveredDateTime
            }catch{
                $LastUnifiedGroupConversationDate = "No conversations"
            }
        }else{
            $LastUnifiedGroupConversationDate = "No conversations"
        }
    }

    #build object to export
    $UnifiedGroupData = New-Object System.Object
    $UnifiedGroupData | Add-Member -MemberType NoteProperty -Name DisplayName -Value $UnifiedGroup.displayName
    $UnifiedGroupData | Add-Member -MemberType NoteProperty -Name ID -Value $UnifiedGroup.id
    $UnifiedGroupData | Add-Member -MemberType NoteProperty -Name MailNickName -Value $UnifiedGroup.mailNickname

    $UnifiedGroupData | Add-Member -MemberType NoteProperty -Name SecurityEnabled -Value $UnifiedGroup.securityEnabled
    $UnifiedGroupData | Add-Member -MemberType NoteProperty -Name Visibility -Value $UnifiedGroup.visibility
    $UnifiedGroupData | Add-Member -MemberType NoteProperty -Name membershipRule -Value $(if([string]::IsNullOrEmpty($UnifiedGroup.membershipRule)){"Assigned"}else{"Dynamic"})   

    $UnifiedGroupData | Add-Member -MemberType NoteProperty -Name LastConversationDate -Value $LastUnifiedGroupConversationDate
    $UnifiedGroupData | Add-Member -MemberType NoteProperty -Name LastContentModifiedDate -Value $(GetGroupLastContentModified "https://graph.microsoft.com/v1.0/groups/" $UnifiedGroup.id $token $TenantDomainName $ApplicationID $CertThumbprint)

    $UnifiedGroupData | Add-Member -MemberType NoteProperty -Name RecordDate -Value $(GetCurrentDateTime)
    $UnifiedGroupData | Add-Member -MemberType NoteProperty -Name ExportDate -Value $ScriptDate
    $UnifiedGroupDataCollection += $UnifiedGroupData


    $i++
}

#export
$UnifiedGroupDataCollection | Export-csv c:\temp\10_M365GroupUsageReport.csv -NoTypeInformation -Encoding utf8


$stopwatch.Stop()

write-host -ForegroundColor Yellow "Completed getting $($FilteredUGroupsCount) in $([Math]::Ceiling($stopwatch.Elapsed.TotalMinutes)) minute(s)"
write-host -ForegroundColor Yellow "Saved output to C:\temp\10_m365groupgsagereport.csv"

