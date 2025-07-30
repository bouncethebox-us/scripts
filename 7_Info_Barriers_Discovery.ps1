<#
.SYNOPSIS
  This script retrieves the information barrier policies and segments deployed to the tenant.
.DESCRIPTION
  Use this script to update the information barrier mode from "Open" to "Implicit" across the groups in your tenant.
#>


# Connect-ExchangeOnline -UserPrincipalName upn@domain.com
Connect-IPPSSession -UserPrincipalName upn@domain.com

Get-InformationBarrierPolicy |
    Select-Object Name, State, AssignedSegment, Segments |
    Export-Csv -Path "C:\temp\07_infobarriers.csv" -NoTypeInformation
