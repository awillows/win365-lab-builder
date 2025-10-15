<#
.SYNOPSIS
    Quick reference for discovering and working with licenses in your tenant.

.DESCRIPTION
    This script demonstrates how to use Get-LabAvailableLicense to discover
    licenses before assigning them with Set-LabGroupLicense.

.NOTES
    Run this script to understand what licenses are available in your tenant
    before attempting to assign them to groups.
#>

# Import the module
Import-Module "$PSScriptRoot\..\W365LabBuilder.psd1" -Force

# Connect to Microsoft Graph
Connect-LabGraph

#region License Discovery

# Step 1: List ALL licenses in your tenant
Write-Host "=== All Licenses in Tenant ===" -ForegroundColor Cyan
$allLicenses = Get-LabAvailableLicense
$allLicenses | Format-Table SkuPartNumber, ProductName, AvailableUnits, ConsumedUnits

# Step 2: Find licenses with available capacity
Write-Host "`n=== Licenses with Available Units ===" -ForegroundColor Cyan
$availableLicenses = Get-LabAvailableLicense | Where-Object AvailableUnits -gt 0
$availableLicenses | Format-Table SkuPartNumber, ProductName, AvailableUnits

# Step 3: Get detailed information for a specific license
Write-Host "`n=== Detailed License Information ===" -ForegroundColor Cyan
Write-Host "Enter a SkuPartNumber from the list above (e.g., ENTERPRISEPACK):" -ForegroundColor Yellow
# For scripting, you can specify directly:
$skuPartNumber = "ENTERPRISEPACK"  # Office 365 E3
$licenseDetails = Get-LabAvailableLicense -SkuPartNumber $skuPartNumber

if ($licenseDetails) {
    Write-Host "`nLicense: $($licenseDetails.ProductName)" -ForegroundColor Green
    Write-Host "SKU Part Number: $($licenseDetails.SkuPartNumber)"
    Write-Host "Available Units: $($licenseDetails.AvailableUnits)"
    Write-Host "Consumed Units: $($licenseDetails.ConsumedUnits)"
    Write-Host "Enabled Units: $($licenseDetails.EnabledUnits)"
    
    Write-Host "`nService Plans Included:" -ForegroundColor Yellow
    $licenseDetails.ServicePlans | Format-Table ServicePlanName, AppliesTo -AutoSize
}
else {
    Write-Host "License '$skuPartNumber' not found in tenant" -ForegroundColor Red
}

#endregion

#region Common License SKUs

Write-Host "`n=== Common License SKU Part Numbers ===" -ForegroundColor Cyan
Write-Host @"

Common Microsoft 365 Licenses:
- ENTERPRISEPACK          : Office 365 E3
- ENTERPRISEPREMIUM       : Office 365 E5
- SPE_E3                  : Microsoft 365 E3
- SPE_E5                  : Microsoft 365 E5
- EMSPREMIUM              : Enterprise Mobility + Security E5
- EMS                     : Enterprise Mobility + Security E3
- POWER_BI_PRO            : Power BI Pro
- FLOW_FREE               : Power Automate Free
- TEAMS_EXPLORATORY       : Microsoft Teams Exploratory

Windows 365 Licenses:
- CPC_E_2C_4GB_64GB_KL    : Windows 365 Enterprise 2vCPU/4GB/64GB
- CPC_E_2C_4GB_128GB_KL   : Windows 365 Enterprise 2vCPU/4GB/128GB
- CPC_E_2C_8GB_128GB_KL   : Windows 365 Enterprise 2vCPU/8GB/128GB
- CPC_E_4C_16GB_256GB_KL  : Windows 365 Enterprise 4vCPU/16GB/256GB

Note: Your tenant may have different SKUs. Use Get-LabAvailableLicense to see what's available.
"@ -ForegroundColor Yellow

#endregion

#region Practical Workflow

Write-Host "`n=== Practical License Assignment Workflow ===" -ForegroundColor Cyan

# 1. Find licenses with capacity
Write-Host "`nStep 1: Find licenses with available capacity" -ForegroundColor Yellow
$availableLicenses = Get-LabAvailableLicense | Where-Object AvailableUnits -gt 10
Write-Host "Found $($availableLicenses.Count) licenses with 10+ available units"

# 2. Pick a license
if ($availableLicenses.Count -gt 0) {
    $selectedLicense = $availableLicenses[0]
    Write-Host "`nStep 2: Selected license: $($selectedLicense.ProductName)" -ForegroundColor Yellow
    Write-Host "SKU Part Number: $($selectedLicense.SkuPartNumber)"
    Write-Host "Available Units: $($selectedLicense.AvailableUnits)"
    
    # 3. Assign to group (WhatIf for safety)
    Write-Host "`nStep 3: Assign to group (WhatIf)" -ForegroundColor Yellow
    Set-LabGroupLicense -GroupName "LabLicenseGroup" `
                        -SkuPartNumber $selectedLicense.SkuPartNumber `
                        -WhatIf
    
    Write-Host "`nTo actually assign, remove -WhatIf and run:" -ForegroundColor Green
    Write-Host "Set-LabGroupLicense -GroupName 'LabLicenseGroup' -SkuPartNumber '$($selectedLicense.SkuPartNumber)'"
}
else {
    Write-Host "`nNo licenses with sufficient capacity found" -ForegroundColor Red
}

#endregion

#region Filtering Examples

Write-Host "`n=== License Filtering Examples ===" -ForegroundColor Cyan

# Find Windows 365 licenses
Write-Host "`nWindows 365 Licenses:" -ForegroundColor Yellow
Get-LabAvailableLicense | Where-Object SkuPartNumber -like "CPC_*" | 
    Format-Table SkuPartNumber, ProductName, AvailableUnits

# Find Office 365 licenses
Write-Host "`nOffice 365 Licenses:" -ForegroundColor Yellow
Get-LabAvailableLicense | Where-Object ProductName -like "*Office 365*" |
    Format-Table SkuPartNumber, ProductName, AvailableUnits

# Find Microsoft 365 licenses
Write-Host "`nMicrosoft 365 Licenses:" -ForegroundColor Yellow
Get-LabAvailableLicense | Where-Object ProductName -like "*Microsoft 365*" |
    Format-Table SkuPartNumber, ProductName, AvailableUnits

# Find licenses low on capacity (< 5 available)
Write-Host "`nLicenses Low on Capacity:" -ForegroundColor Yellow
Get-LabAvailableLicense | Where-Object { $_.AvailableUnits -gt 0 -and $_.AvailableUnits -lt 5 } |
    Format-Table SkuPartNumber, ProductName, AvailableUnits, ConsumedUnits

#endregion

Write-Host "`n=== License Discovery Complete ===" -ForegroundColor Green
Write-Host "Use the SkuPartNumber values with Set-LabGroupLicense to assign licenses to groups."

# Disconnect
Disconnect-LabGraph
