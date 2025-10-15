<#
.SYNOPSIS
    Example script demonstrating shared group creation for Cloud PC provisioning.

.DESCRIPTION
    This script shows how to create a lab environment where all users are placed
    in a single shared group, which is then assigned to a Cloud PC provisioning policy.
    This is useful when you want all users to share the same Cloud PC configuration
    without creating individual groups for each user.

.NOTES
    This is the third assignment option, alongside:
    1. Individual groups (one per user)
    2. Default license group (pre-existing)
    3. Shared group (new - all users in one group)
#>

# Import the Windows 365 Lab Builder module
Import-Module "$PSScriptRoot\..\W365LabBuilder\W365LabBuilder.psd1" -Force

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-LabGraph -UseDeviceCode

# Example 1: Create lab with shared group
Write-Host "`nExample 1: Creating 50 users with shared group assignment" -ForegroundColor Yellow
$result = New-LabEnvironment `
    -UserCount 50 `
    -UserPrefix "demo" `
    -CreateSharedGroup `
    -CreateProvisioningPolicies `
    -AssignPolicies `
    -RegionName "eastus" `
    -Verbose

Write-Host "`nResults:" -ForegroundColor Green
Write-Host "  Users created: $($result.Users.Count)"
Write-Host "  Groups created: $($result.Groups.Count)"
Write-Host "  Policies created: $($result.Policies.Count)"
Write-Host "  Duration: $($result.Duration.TotalSeconds) seconds"

# Display the shared group details
if ($result.Groups.Count -gt 0) {
    $sharedGroup = $result.Groups[0]
    Write-Host "`nShared Group Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($sharedGroup.DisplayName)"
    Write-Host "  ID: $($sharedGroup.Id)"
    
    # Get group members count
    $members = Get-MgGroupMember -GroupId $sharedGroup.Id
    Write-Host "  Members: $($members.Count)"
}

# Example 2: Compare the three assignment options
Write-Host "`n`nComparison of Assignment Options:" -ForegroundColor Yellow
Write-Host "1. Individual Groups (-CreateIndividualGroups):" -ForegroundColor Cyan
Write-Host "   - Creates one group per user"
Write-Host "   - Provides maximum granularity"
Write-Host "   - Example: 100 users = 100 groups"
Write-Host ""
Write-Host "2. Shared Group (-CreateSharedGroup):" -ForegroundColor Cyan
Write-Host "   - Creates ONE group for all users"
Write-Host "   - Simplifies management"
Write-Host "   - Example: 100 users = 1 group"
Write-Host ""
Write-Host "3. Default License Group (no group flag):" -ForegroundColor Cyan
Write-Host "   - Uses existing license group"
Write-Host "   - No new groups created"
Write-Host "   - Example: All users already in license group"

Write-Host "`nScript completed!" -ForegroundColor Green
