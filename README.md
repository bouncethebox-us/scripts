# Oversharing and Broad-sharing discovery
Discovery scripts useful in assessing oversharing, broadsharing, lifecycle before deploying Microsoft 365 Copilot

**NOTE:** These scripts do not execute properly using Windows Power Shell ISE and require PowerShell Core or PowerShell Desktop to run.  

Unless otherwise noted, all scripts need to be run as ‘Administrator’ (local admin) from a PowerShell Core or PowerShell Desktop.

## Order of Operations
### Environment Prep  
Part00_Env_Prep_PnP_InteractiveLogin.ps1
This PowerShell script is designed to automate the creation of an Azure Entra ID (formerly Azure AD) Application Registration for use with interactive login scenarios—specifically for scripts that require enumerating web role assignments and similar tasks.
✅ Purpose
•	Creates an Application Registration in Microsoft Entra ID (Azure AD).
•	Intended for use with interactive login scenarios.
•	Sets up the app with:
•	A self-signed certificate
•	A client secret
•	Microsoft Graph API permissions (read-only)
•	Requires Global Administrator privileges.
________________________________________
🔍 Key Components Explained
Directive	Purpose
#Requires -RunAsAdministrator	Ensures the script is run with admin privileges.
#Requires -Version 7.x	Requires PowerShell 7.x or higher.
#Requires - change <insert-tenant-name>.onmicrosoft.com	Placeholder for your Microsoft 365 tenant domain.
#Requires -Module @{ModuleName='Microsoft.Graph'; ModuleVersion='2.19.0'}	Requires the Microsoft Graph PowerShell SDK version 2.19.0.
________________________________________
🛠️ What the Script Does
1.	Creates an App Registration
•	Named PnP4IAMS-UsernameIA, where Username is the prefix of the current user's UPN (e.g., jdoeIA).
2.	Generates a Self-Signed Certificate
•	Used for secure authentication.
3.	Uploads the Certificate to the App Registration
4.	Generates a Client Secret
•	Used as an alternative authentication method.
5.	Assigns Microsoft Graph API Permissions
•	Likely read-only permissions for directory and role enumeration.
6.	Prompts for Admin Consent
•	After creation, you must grant admin consent for the app to use the permissions.



# Application Registration
Part01 -> Part02 -> 

3_Get_SPO_Sites -> 4_OD4B_Discovery -> 5_SPO_Discovery 6_Tenant_Discovery  7_Info_Barriers_Discovery


