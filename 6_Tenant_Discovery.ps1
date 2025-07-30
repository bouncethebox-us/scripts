# Requires PowerShell 7.x and PnP.PowerShell
# Run as Administrator

# Set SharePoint Online Admin Center URL
$AdminCenterURL = "https://tenantname-admin.sharepoint.com"

# Connect to PnP
Connect-PnPOnline -Url $AdminCenterURL -UseWebLogin

# Get Tenant Settings
$TenantSettings = Get-PnPTenant

# Export to CSV
$TenantSettings | Export-Csv -Path "C:\temp\06_SPO_Tenant_Settings.csv" -NoTypeInformation
Write-Host "Tenant settings exported to C:\temp\06_SPO_Tenant_Settings.csv"
