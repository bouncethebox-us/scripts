#This script enumerates all teams and retrieves the last post for all team channels (NOT accounting for replies) and last user content modified for the team.
#help
#https://learn.microsoft.com/en-us/graph/api/channel-list-messages?view=graph-rest-1.0&tabs=http
    #ChannelMessage.Read.Group
    #Do we need RSC????  https://learn.microsoft.com/en-us/microsoftteams/platform/graph-api/rsc/resource-specific-consent or https://learn.microsoft.com/en-us/microsoftteams/platform/graph-api/rsc/grant-resource-specific-consent
#https://learn.microsoft.com/en-us/graph/teams-list-all-teams

#need certificate too
#classic sharepoint sites.fullcontrol


$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
Connect-MicrosoftTeams

#Replace 'X' with values from Part02 script Output
#Variables
#$GraphURLPrefix =
#PlanetReporting
$CertThumbprint = 'xxxxxxxxxxxxxxxxxx'
$ApplicationID = 'xxxxxxx-xxxx-xxxx-xxxx-4870476d4bd1'
$TenantDomainName = 'tenantname.onmicrosoft.com'
$AppRegSecret = 'xxxxxxxxxxxxxxxxxx'




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


function Convert-UTCtoLocal($Time)
{
    $UTCTime = (Get-Date $Time).ToUniversalTime()
    $strCurrentTimeZone = (Get-WmiObject win32_timezone).StandardName 
    $TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone) 
    $LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TZ)
    return $LocalTime
}


Function ParseTeamStorageLocation($SPStorageLocation)
{
    try{
        $Seperator = '/Shared%20Documents'
        $TeamChannelWebURL = ($SPStorageLocation -split $Seperator)[0]
    }catch{
        $TeamChannelWebURL = $null
    }
    
    return $TeamChannelWebURL
}


Function GetTeamFileLastModified($GraphCallURLPrefix,$TeamGroupID,$ChannelID){

    try{
        #get storage location
        $SPSite = $null
        #https://learn.microsoft.com/en-us/graph/api/channel-get-filesfolder?view=graph-rest-1.0&tabs=http
        $GraphUrl = $GraphCallURLPrefix + $TeamGroupID + "/channels/" + $ChannelID + "/filesFolder"
        $RestCall = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $GraphUrl -Method Get
        $SPSite = ParseTeamStorageLocation $RestCall.webUrl

        

        if([string]::IsNullOrEmpty($SPSite))
        {
            #empty no site
            $ContentLastModifiedDate = "No team channel storage location"
        }else{
            #has a site
            try{
                Connect-PnPOnline -Tenant $TenantDomainName -ClientId $ApplicationID -Thumbprint $CertThumbprint -Url $SPSite
                $ContentLastModifiedDate = Convert-UTCtoLocal ((get-pnplist 'Documents').LastItemUserModifiedDate)
            }catch{
                $ContentLastModifiedDate = "Content Last Modified failed: $($_.Exception.Message)"
            }
        }
        #
        
    }catch{
        $ContentLastModifiedDate = "Channel storage location failed: $($_.Exception.Message)"
    }
    
    
    Return $ContentLastModifiedDate
}



Function GetTeamLastActivity($GraphCallURLPrefix,$TeamGroupID){

    #get the channels
    $TeamChannels = @()
    $PostDataCollection = @()
    $ContentDataCollection = @()

    #new
    $TeamLastActivity = @()
    
    Try{
        #https://learn.microsoft.com/en-us/graph/api/channel-list?view=graph-rest-1.0&tabs=http
        $GraphUrl = $GraphCallURLPrefix + $TeamGroupID + "/channels/"
        $RestCall = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $GraphUrl -Method Get
        $TeamChannels += $RestCall.value# | ?{$_.body.content -ne '<systemEventMessage/>'}

        while($restcall.'@odata.nextLink' -ne $null)
        {
            $RestCall = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $restcall.'@odata.nextLink'-Method Get
            $TeamChannels += $RestCall.value# | ?{$_.body.content -ne '<systemEventMessage/>'}
        }

        Try{
            #get the last post for each channel
            foreach($Channel in $TeamChannels)
            {
                ###### Loop to collect all the TeamChannel Info
                $GraphUrl = $GraphCallURLPrefix + $TeamGroupID + "/channels/" + $Channel.Id + "/messages"
                $RestCall = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $GraphUrl -Method Get
                $PostDataCollection += $RestCall.value | ?{$_.body.content -ne '<systemEventMessage/>'}
                
                while($restcall.'@odata.nextLink' -ne $null)
                {
                    $RestCall = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Token)"} -Uri $restcall.'@odata.nextLink'-Method Get
                    $PostDataCollection += $RestCall.value | ?{$_.body.content -ne '<systemEventMessage/>'}
                }  

                ##########loop to collect content last modified
                $ContentDataCollection += $(GetTeamFileLastModified $GraphCallURLPrefix $TeamGroupID $Channel.Id)

            }

            #got all the posts, evaluate for last
            if($PostDataCollection.count -ge 1){

                $LastTeamPost = Convert-UTCtoLocal (($PostDataCollection | Sort-Object -property lastModifiedDateTime -Descending)[0]).lastModifiedDateTime

            }else{
                $LastTeamPost = "No Posts"    
            }

            #got all the last content dates, evaluate for last
            #filter out dates
            #$LastContentModifiedDate = $null
            
            
            if($ContentDataCollection.count -ge 1){
                $LastContentModifiedDate = ($ContentDataCollection | ?{$_.gettype().Name -eq 'DateTime'} | Sort-Object -Descending)[0]
            }else{
                $LastContentModifiedDate = "No content"
            }
            
        }catch{
            $LastTeamPost = "Channels Retrieved, Failed to retrieve LastPost: $($_.Exception.Message)"
        }
    }catch{
        $LastTeamPost = "Failed to retrieve Team Channels: $($_.Exception.Message)"
    }

    write-host -ForegroundColor Magenta "  LastTeamPost:: $($LastTeamPost)"
    write-host -ForegroundColor Cyan "  LastContentModifiedDate:: $($LastContentModifiedDate)"

    return $LastTeamPost, $LastContentModifiedDate
    #return $TeamLastActivity
}

#not using graph due to known issue
#

#collect Teams
$Teams = Get-Team  -NumberOfThreads 6
$TeamsCount = $Teams.Count
$ScriptDate = (get-Date).ToString("MM/dd/yyyy")

$Token = (GetToken 'client_credentials' $ApplicationID $AppRegSecret 'https://graph.microsoft.com/.default' 'https://login.microsoftonline.com/' $TenantDomainName).access_token

$TeamsDataCollection = @()
$i=1
#collect Team Channels
foreach($Team in $Teams)
{
    write-host -ForegroundColor Yellow "Processing Teams: $($i) of $($TeamsCount):: $($Team.DisplayName)"

    $TeamLastActivity = GetTeamLastActivity "https://graph.microsoft.com/v1.0/teams/" $Team.GroupId

    $TeamChannelData = New-Object System.Object
    $TeamChannelData | Add-Member -MemberType NoteProperty -Name TeamDisplayName -Value $Team.DisplayName
    $TeamChannelData | Add-Member -MemberType NoteProperty -Name TeamGroupID -Value $Team.GroupId
    $TeamChannelData | Add-Member -MemberType NoteProperty -Name TeamMailNickName -Value $Team.MailNickName
    $TeamChannelData | Add-Member -MemberType NoteProperty -Name LastPostDate -Value $($TeamLastActivity[0])
    $TeamChannelData | Add-Member -MemberType NoteProperty -Name LastContentModifiedDate -Value $($TeamLastActivity[1])
    $TeamChannelData | Add-Member -MemberType NoteProperty -Name RecordDate -Value $(Get-Date)
    $TeamChannelData | Add-Member -MemberType NoteProperty -Name ExportDate -Value $ScriptDate
    $TeamsDataCollection += $TeamChannelData

    $i++
}
$TeamsDataCollection | Export-csv C:\temp\wmata-discovery\teamsusagereport.csv -NoTypeInformation -Encoding utf8


$stopwatch.Stop()

write-host -ForegroundColor Yellow "Completed getting $($TeamsCount) in $([Math]::Ceiling($stopwatch.Elapsed.TotalMinutes)) minute(s)"
write-host -ForegroundColor Yellow "C:\temp\wmata-discovery\teamsusagereport.csv"

