#Requires -RunAsAdministrator
#Requires -Version 5
#Requires -PSEdition Desktop
##Requires -Module @{ModuleName='Microsoft.Graph'; ModuleVersion='2.19.0'}



<#
	  .SYNOPSIS
		Generates an Application Registration in Entra ID for Copilot engagements. API permissions are based on read.
	  .DESCRIPTION
      	Creates Application Registration titled 'PlanetReporting'. Requires Global Administrator in Office 365. You must grant consent after the script runs.
        Creates a self-signed certificate, creates app registration, uploads self-signed certificate, generates secret and assigns API permissions.
        Uses the Microsoft Graph SDK. More Information found here: https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0
	  .EXAMPLE
	  	.\CreateAppRegistration_Readiness.ps1
	  .EXAMPLE
	  	.\CreateAppRegistration_Readiness.ps1 -GCCH
	  .PARAMETER GCCH
	  	Switch parameter to specify if the tenant is GCCH. Excluding this the tenant is assumed to be Commercial, EDU, GCC
#>

[CmdletBinding()]
	Param(
		[Parameter(ParameterSetName='Default',Mandatory=$false,Position=1)]
			[switch]$GCCH
        )


#Variables

$ErrorCount = 0 
$AppRegistrationName = 'Copilot_Readiness'


#Connect
If($GCCH)
{
	#Connect to GCCH
	try {
        Connect-MgGraph -Scopes "Application.ReadWrite.All" -NoWelcome -Environment USGov
        write-host -ForegroundColor Green "Connected to Entra ID: GCC High"
        $TenantID = (Get-MgOrganization).Id
    }
    catch {
        write-host -ForegroundColor Red "Failed to connect to Entra ID:: $($_.Exception.Message)"
        exit
    }
}else{
	#Connect-MgGraph -Scopes "Application.Read.All","Application.ReadWrite.All","User.Read.All"
    try {
        Connect-MgGraph -Scopes "Application.ReadWrite.All" -NoWelcome
        write-host -ForegroundColor Green "Connected to Entra ID"
        $TenantID = (Get-MgOrganization).Id
    }
    catch {
        write-host -ForegroundColor Red "Failed to connect to Entra ID:: $($_.Exception.Message)"
        exit
    }
}

$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

Try{
    #Generate Certificate
    $certParams = @{
        Subject = "CN=$AppRegistrationName"
        DnsName = $AppRegistrationName
        CertStoreLocation = 'cert:\LocalMachine\My'
        NotAfter = (Get-Date).AddMonths(6)
        KeySpec = 'KeyExchange'
        Provider = 'Microsoft Enhanced RSA and AES Cryptographic Provider'
        KeyExportPolicy = 'Exportable'
    }
    $mycert = New-SelfSignedCertificate @certParams

    $cert = Get-ChildItem -Path "cert:\localmachine\my\$($mycert.Thumbprint)"

    $CertCredentials = @(
        @{
            Type = "AsymmetricX509Cert"
            Usage = "Verify"
            Key = [byte[]]$cert.RawData
        }
        )

}catch{
    write-host -ForegroundColor Red "Failed to generate certificate: $($_.Exception.Message)"
    exit
}


#create the app registration
try{
    $appName =  $AppRegistrationName
    $app = New-MgApplication -DisplayName $appName
    $appObjectId = $app.Id
    write-host -ForegroundColor Green "Created app registration:: $($appObjectId)"
}catch{
    write-host -ForegroundColor Red "Failed to create app registration: $($_.Exception.Message)"
    exit
}


#update the app registration with certificate
try{
    Update-MgApplication -ApplicationId $appObjectId -KeyCredentials $CertCredentials
    write-host -ForegroundColor Green "Uploaded cert to app registration."
}catch{
    write-host -ForegroundColor Red "Failed to upload cert to app registration."
    $ErrorCount += 1
}


#generate secret
try {
    $passwordCred = @{
        #displayName = 'Created in PowerShell'
        endDateTime = (Get-Date).AddMonths(6)
     }
    $secret = Add-MgApplicationPassword -applicationId $appObjectId -PasswordCredential $passwordCred
    #SecretText
    write-host -ForegroundColor Green "Generated client secret"
}
catch {
    write-host -ForegroundColor Red "Failed to generated client secret: $($_.Exception.Message)"
    $ErrorCount += 1
}

#assigned api permissions
try{
    #Permissions Guide: https://learn.microsoft.com/en-us/graph/permissions-reference#resource-specific-consent-rsc-permissions
    #Graph Resource App ID: 00000003-0000-0000-c000-000000000000
    #SharePoint Resource App ID: 00000003-0000-0ff1-ce00-000000000000
    $permissionParams = @{
        RequiredResourceAccess = @(
            @{
                ResourceAppId = "00000003-0000-0000-c000-000000000000"
                ResourceAccess = @(
                    @{
                        Id = "7b2449af-6ccd-4f4d-9f78-e550c193f0d1"
                        Type = "Role"
                    }
                    @{
                        Id = "c97b873f-f59f-49aa-8a0e-52b32d762124"
                        Type = "Role"
                    }
                    @{
                        Id = "01d4889c-1287-42c6-ac1f-5d1e02578ef6"
                        Type = "Role"
                    }
                    @{
                        Id = "5b567255-7703-4780-807c-7be8301ae99b"
                        Type = "Role"
                    }
                    @{
                        Id = "98830695-27a2-44f7-8c18-0c3ebc9698f6"
                        Type = "Role"
                    }
                    @{
                        Id = "2280dda6-0bfd-44ee-a2f4-cb867cfc4c1e"
                        Type = "Role"
                    }
                    @{
                        Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
                        Type = "Role"
                    }
                )
            }
            @{
                ResourceAppId = "00000003-0000-0ff1-ce00-000000000000"
                ResourceAccess = @(
                    @{
                        Id = "d13f72ca-a275-4b96-b789-48ebcc4da984"
                        Type = "Role"
                    }
                )
            }
        )
    }
    Update-MgApplication -ApplicationId $appObjectId -BodyParameter $permissionParams
    write-host -ForegroundColor Green "Assigned API Permissions"
}catch{
    write-host -ForegroundColor Red "Failed to assign API permissions: $($_.Exception.Message)"
    $ErrorCount += 1
}

if($ErrorCount -eq 0)
{
    write-host -ForegroundColor Yellow "----------------------------------------------------"
    Write-Host -ForegroundColor Green "Application Registration configured correctly.  Navigate to Entra ID, locate the app registration and Grant consent. The app registration will not function until this is done."
    Write-Host -ForegroundColor Yellow "`nThe below information is not saved and displayed in this session of PowerShell only. Note all values to update scripts"
    write-host -ForegroundColor Yellow "----------------------------------------------------"
    Write-host "App Registration Name: $($AppRegistrationName)"
    Write-Host "Client ID: $($app.AppID)"
    Write-Host "Tenant ID: $($TenantID)"
    Write-Host "Cert Thumbprint: $($mycert.Thumbprint)"
    Write-Host "Secret Value: $($secret.SecretText)"
    write-host -ForegroundColor Yellow "----------------------------------------------------"
}else{
    write-host -ForegroundColor Yellow "----------------------------------------------------"
    Write-Host -ForegroundColor Red "Application Registration not configured correctly, determine best approach based on errors in this script for remediation."
    Write-Host -ForegroundColor Yellow "`nThe below information is not saved and displayed in this session of PowerShell only. Note all values to update scripts"
    write-host -ForegroundColor Yellow "----------------------------------------------------"
    Write-host "App Registration Name: $($AppRegistrationName)"
    Write-Host "Client ID: $($app.AppID)"
    Write-Host "Tenant ID: $($TenantID)"
    Write-Host "Cert Thumbprint: $($mycert.Thumbprint)"
    Write-Host "Secret Value: $($secret.SecretText)"
    write-host -ForegroundColor Yellow "----------------------------------------------------"
}

#Stop Timer
$stopwatch.Stop()

#wrap up
write-host -ForegroundColor Yellow "Completed configuration of the app registration in $([Math]::Ceiling($stopwatch.Elapsed.TotalMinutes)) minute(s)"


