#Requires -RunAsAdministrator
#Requires -Version 7.x
#Requires -PSEdition Desktop
#Requires - change <insert-tenant-name>.onmicrosoft.com 
##Requires -Module @{ModuleName='Microsoft.Graph'; ModuleVersion='2.19.0'}

<#
	  .SYNOPSIS
		Generates an Application Registration in Entra for InteractiveLogin when provisioning the required Enterprise Application for EnumWebRoleAssignments and other scripts. API permissions are based on read.
	  .DESCRIPTION
      	Creates Application Registration titled 'PnP4IAMS-UsernameIA, where Username is owner upn prefix. Requires Global Administrator in Microsoft/Office 365. You must grant consent after the script runs.
        Creates a self-signed certificate, creates app registration, uploads self-signed certificate, generates secret and assigns API permissions.
        Uses the Microsoft Graph SDK. More Information found here: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
	  .EXAMPLE
	  	.\Register-PnPEntraIDAppForInteractiveLogin.ps1 
#>

#Requires -RunAsAdministrator
Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP4IAMS-UsernameIA" -Tenant <insert-tenant-name>.onmicrosoft.com -AzureEnvironment USGovernment