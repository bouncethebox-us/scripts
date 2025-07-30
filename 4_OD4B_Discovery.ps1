#Requires PowerShell 5.x
#Requires SharePoint PowerShell Module
#Requires Run as Administrator

#Variable for SharePoint Online Admin Center URL
$AdminSiteURL="https://tenantname-admin.sharepoint.com"
$CSVFile = "C:\temp\04_onedrives.csv"
  
#Connect to SharePoint Online Admin Center
Connect-SPOService -Url $AdminSiteURL
 
#Get All OneDrive Sites usage details and export to CSV
Get-SPOSite -IncludePersonalSite $true -Limit all -Filter "Url -like '-my.sharepoint.com/personal/'" | Select URL, Owner, StorageQuota, StorageUsageCurrent, LastContentModifiedDate | Export-Csv -Path $CSVFile -NoTypeInformation
