<#
.SYNOPSIS
    Example script demonstrating license management for lab environments.

.DESCRIPTION
    This script shows how to use the license management functions to assign
    licenses to groups, manage license assignments, and query license status.

.NOTES
    Requires:
    - Microsoft Graph permissions: Group.ReadWrite.All, Directory.ReadWrite.All
    - Available licenses in the tenant
    - Security groups (not mail-enabled)
#>

# Import the module
Import-Module "$PSScriptRoot\..\W365LabBuilder.psd1" -Force

# Connect to Microsoft Graph
Connect-LabGraph -TenantId "your-tenant-id"

# Example 1: Discover Available Licenses
# Query all licenses in your tenant before assigning
Write-Host "Example 1: Discovering available licenses in tenant..." -ForegroundColor Cyan
$availableLicenses = Get-LabAvailableLicense
Write-Host "Found $($availableLicenses.Count) license(s) in tenant" -ForegroundColor Green
$availableLicenses | Format-Table SkuPartNumber, ProductName, AvailableUnits, ConsumedUnits, EnabledUnits

# Find licenses with available units
Write-Host "`nLicenses with available units:" -ForegroundColor Yellow
$availableLicenses | Where-Object AvailableUnits -gt 0 | Format-Table SkuPartNumber, ProductName, AvailableUnits

# Get detailed information for a specific license
Write-Host "`nDetailed information for Office 365 E3:" -ForegroundColor Yellow
Get-LabAvailableLicense -SkuPartNumber "ENTERPRISEPACK" | Format-List

# Example 2: Basic License Assignment
# Assign a single license to a group
Write-Host "`nExample 2: Assigning Office 365 E3 license to lab group..." -ForegroundColor Cyan
Set-LabGroupLicense -GroupName "LabLicenseGroup" -SkuPartNumber "ENTERPRISEPACK"

# Wait for assignment to process
Start-Sleep -Seconds 5

# Verify the assignment
$licenses = Get-LabGroupLicense -GroupName "LabLicenseGroup"
Write-Host "Assigned Licenses:" -ForegroundColor Green
$licenses | Format-Table GroupName, SkuPartNumber, ProductName, ConsumedUnits, PrepaidUnits

# Example 3: Assign Multiple Licenses
# Useful for comprehensive lab setups
Write-Host "`nExample 3: Assigning multiple licenses..." -ForegroundColor Cyan
Set-LabGroupLicense -GroupName "LabLicenseGroup" -SkuPartNumber "ENTERPRISEPACK","EMSPREMIUM"

# Check all licenses
$licenses = Get-LabGroupLicense -GroupName "LabLicenseGroup"
Write-Host "Total licenses assigned: $($licenses.Count)" -ForegroundColor Green
$licenses | Format-Table SkuPartNumber, ProductName

# Example 4: Complete Lab Setup with Licensing
Write-Host "`nExample 4: Creating complete lab with licensing..." -ForegroundColor Cyan

# Create users
$users = New-LabUser -UserCount 10 -UserPrefix "licensed" -Password "SecurePass123!" -Verbose

# Create dedicated license group
$licenseGroup = New-LabGroup -GroupName "Licensed Lab Users" -Description "Group for licensed lab users"

# Add users to group
foreach ($user in $users) {
    Add-LabUserToGroup -UserPrincipalName $user.UserPrincipalName -GroupId $licenseGroup.Id
}

# Assign licenses to the group (all members will receive licenses automatically)
Set-LabGroupLicense -GroupId $licenseGroup.Id -SkuPartNumber "ENTERPRISEPACK"

Write-Host "Lab setup complete! All users will receive licenses via group membership." -ForegroundColor Green

# Example 5: Managing License Assignments
Write-Host "`nExample 5: Managing license assignments..." -ForegroundColor Cyan

# Query current licenses
$currentLicenses = Get-LabGroupLicense -GroupName "Licensed Lab Users"
Write-Host "Current licenses:" -ForegroundColor Yellow
$currentLicenses | Format-Table SkuPartNumber, ConsumedUnits, PrepaidUnits

# Remove a specific license
if ($currentLicenses.Count -gt 1) {
    Write-Host "Removing EMS Premium license..." -ForegroundColor Yellow
    Remove-LabGroupLicense -GroupName "Licensed Lab Users" -SkuPartNumber "EMSPREMIUM" -Confirm:$false
}

# Verify removal
$remainingLicenses = Get-LabGroupLicense -GroupName "Licensed Lab Users"
Write-Host "Remaining licenses: $($remainingLicenses.Count)" -ForegroundColor Green

# Example 6: Using Available License Data
Write-Host "`nExample 6: Using available license information for decisions..." -ForegroundColor Cyan

# Get licenses with service plan details
$detailedLicenses = Get-LabAvailableLicense | Where-Object AvailableUnits -gt 0
Write-Host "Licenses with available capacity:" -ForegroundColor Yellow
$detailedLicenses | Format-Table SkuPartNumber, ProductName, AvailableUnits

# Show service plans for a specific license
$license = Get-LabAvailableLicense -SkuPartNumber "ENTERPRISEPACK"
if ($license) {
    Write-Host "`nService plans included in $($license.ProductName):" -ForegroundColor Yellow
    $license.ServicePlans | Format-Table ServicePlanName, AppliesTo
}

# Example 7: License Assignment with Disabled Plans
Write-Host "`nExample 7: Assigning license with specific service plans disabled..." -ForegroundColor Cyan

# Get service plans for a license
$sku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq "ENTERPRISEPACK" } | Select-Object -First 1

if ($sku) {
    Write-Host "Available service plans in $($sku.SkuPartNumber):" -ForegroundColor Yellow
    $sku.ServicePlans | Format-Table ServicePlanName, ServicePlanId
    
    # Example: Disable specific plans (e.g., Yammer)
    # $disabledPlans = $sku.ServicePlans | Where-Object { $_.ServicePlanName -eq "YAMMER_ENTERPRISE" } | Select-Object -ExpandProperty ServicePlanId
    # Set-LabGroupLicense -GroupName "Licensed Lab Users" -SkuPartNumber "ENTERPRISEPACK" -DisabledPlans $disabledPlans
}

# Example 7: Complete Cleanup
Write-Host "`nExample 7: Complete cleanup..." -ForegroundColor Cyan

# Prompt for confirmation
$confirm = Read-Host "Do you want to clean up all lab resources? (yes/no)"

if ($confirm -eq "yes") {
    # Remove all licenses first
    Write-Host "Removing all licenses from group..." -ForegroundColor Yellow
    Remove-LabGroupLicense -GroupName "Licensed Lab Users" -RemoveAll -Confirm:$false
    
    # Wait for license removal to process
    Start-Sleep -Seconds 10
    
    # Remove users
    Write-Host "Removing users..." -ForegroundColor Yellow
    Remove-LabUser -UserPrefix "licensed" -Force
    
    # Remove groups
    Write-Host "Removing groups..." -ForegroundColor Yellow
    Remove-LabGroup -GroupName "Licensed Lab Users" -Force
    
    Write-Host "Cleanup complete!" -ForegroundColor Green
}
else {
    Write-Host "Cleanup skipped." -ForegroundColor Yellow
}

# Disconnect
Disconnect-LabGraph

Write-Host "`nLicense management examples completed!" -ForegroundColor Green
Write-Host "Remember: License assignments may take a few minutes to propagate to all group members." -ForegroundColor Yellow
