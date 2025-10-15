<#
.SYNOPSIS
    Example script demonstrating Windows 365 user settings management.

.DESCRIPTION
    This script shows how to create, configure, and manage Windows 365 user settings policies
    that control features like local admin access, self-service restore, and restore point frequency.

.NOTES
    Requires:
    - Microsoft Graph permissions: DeviceManagementConfiguration.ReadWrite.All
    - Windows 365 licenses assigned to target users
    - Security groups configured
#>

# Import the module
Import-Module "$PSScriptRoot\..\W365LabBuilder.psd1" -Force

# Connect to Microsoft Graph
Connect-LabGraph -TenantId "your-tenant-id"

Write-Host "`n=== Windows 365 User Settings Management Examples ===" -ForegroundColor Cyan

# Example 1: Create Basic User Settings Policy
Write-Host "`nExample 1: Creating basic user settings policy..." -ForegroundColor Green

$basicSettings = New-LabCloudPCUserSettings `
    -PolicyName "Lab Basic Settings" `
    -Description "Standard user settings for lab environment" `
    -EnableLocalAdmin $false `
    -EnableSelfServiceRestore $true `
    -RestorePointFrequencyInHours 12

Write-Host "Created policy: $($basicSettings.DisplayName)" -ForegroundColor Yellow
Write-Host "  Local Admin: $($basicSettings.LocalAdminEnabled)" -ForegroundColor Gray
Write-Host "  Self-Service Restore: $($basicSettings.SelfServiceEnabled)" -ForegroundColor Gray
Write-Host "  Restore Frequency: $($basicSettings.RestorePointFrequencyInHours) hours" -ForegroundColor Gray

# Example 2: Create Admin-Enabled Settings
Write-Host "`nExample 2: Creating admin-enabled settings for power users..." -ForegroundColor Green

$adminSettings = New-LabCloudPCUserSettings `
    -PolicyName "Lab Admin Settings" `
    -Description "Settings for users requiring local admin access" `
    -EnableLocalAdmin $true `
    -EnableSelfServiceRestore $true `
    -RestorePointFrequencyInHours 6

Write-Host "Created admin policy: $($adminSettings.DisplayName)" -ForegroundColor Yellow

# Example 3: Create Restricted Settings
Write-Host "`nExample 3: Creating restricted settings for high-security scenarios..." -ForegroundColor Green

$restrictedSettings = New-LabCloudPCUserSettings `
    -PolicyName "Lab Restricted Settings" `
    -Description "Restricted settings with no self-service capabilities" `
    -EnableLocalAdmin $false `
    -EnableSelfServiceRestore $false `
    -RestorePointFrequencyInHours 24

Write-Host "Created restricted policy: $($restrictedSettings.DisplayName)" -ForegroundColor Yellow

# Example 4: List All User Settings Policies
Write-Host "`nExample 4: Listing all user settings policies..." -ForegroundColor Green

$allPolicies = Get-LabCloudPCUserSettings -All
Write-Host "`nFound $($allPolicies.Count) user settings policies:" -ForegroundColor Yellow
$allPolicies | Format-Table DisplayName, LocalAdminEnabled, SelfServiceEnabled, RestorePointFrequencyInHours -AutoSize

# Example 5: Assign User Settings to Groups
Write-Host "`nExample 5: Assigning user settings to groups..." -ForegroundColor Green

# Ensure groups exist
$basicGroup = New-LabGroup -GroupName "Lab Standard Users" -Description "Standard lab users"
$adminGroup = New-LabGroup -GroupName "Lab Admin Users" -Description "Admin lab users"

# Assign basic settings to standard users
Set-LabUserSettingsAssignment `
    -PolicyName "Lab Basic Settings" `
    -GroupName "Lab Standard Users"
Write-Host "Assigned basic settings to Standard Users group" -ForegroundColor Yellow

# Assign admin settings to admin users
Set-LabUserSettingsAssignment `
    -PolicyName "Lab Admin Settings" `
    -GroupName "Lab Admin Users"
Write-Host "Assigned admin settings to Admin Users group" -ForegroundColor Yellow

# Example 6: Complete Lab Setup with User Settings
Write-Host "`nExample 6: Complete lab setup with provisioning and user settings..." -ForegroundColor Green

# Create users
$users = New-LabUser -UserCount 10 -UserPrefix "w365demo" -Password "DemoPass123!"

# Create groups
$demoGroup = New-LabGroup -GroupName "W365 Demo Users" -Description "Windows 365 demo users"

# Add users to group
foreach ($user in $users) {
    Add-LabUserToGroup -UserPrincipalName $user.UserPrincipalName -GroupId $demoGroup.Id
}

# Assign licenses
Set-LabGroupLicense -GroupName "W365 Demo Users" -SkuPartNumber "CPC_E_2"

# Create provisioning policy (uses Microsoft-hosted network by default)
$provPolicy = New-LabCloudPCPolicy `
    -PolicyName "W365 Demo Provisioning" `
    -EnableSingleSignOn

# Optional: Use Azure network connection if available
# $connection = Get-MgDeviceManagementVirtualEndpointOnPremisesConnection | Select-Object -First 1
# if ($connection) {
#     $provPolicy = New-LabCloudPCPolicy `
#         -PolicyName "W365 Demo Provisioning" `
#         -OnPremisesConnectionId $connection.Id `
#         -EnableSingleSignOn
# }

# Assign provisioning policy
Set-LabPolicyAssignment -PolicyId $provPolicy.Id -GroupId $demoGroup.Id

# Create and assign user settings
$demoUserSettings = New-LabCloudPCUserSettings `
    -PolicyName "W365 Demo User Settings" `
    -EnableLocalAdmin $true `
    -EnableSelfServiceRestore $true `
    -RestorePointFrequencyInHours 8

Set-LabUserSettingsAssignment -PolicyId $demoUserSettings.Id -GroupId $demoGroup.Id

Write-Host "`nComplete lab setup finished!" -ForegroundColor Green
Write-Host "  Users: $($users.Count)" -ForegroundColor Gray
Write-Host "  Group: $($demoGroup.DisplayName)" -ForegroundColor Gray
Write-Host "  Provisioning Policy: $($provPolicy.DisplayName)" -ForegroundColor Gray
Write-Host "  User Settings: $($demoUserSettings.DisplayName)" -ForegroundColor Gray

# Example 7: Query Specific User Settings
Write-Host "`nExample 7: Querying specific user settings policy..." -ForegroundColor Green

$specificPolicy = Get-LabCloudPCUserSettings -PolicyName "Lab Admin Settings"
if ($specificPolicy) {
    Write-Host "`nPolicy Details:" -ForegroundColor Yellow
    Write-Host "  Name: $($specificPolicy.DisplayName)" -ForegroundColor Gray
    Write-Host "  Description: $($specificPolicy.Description)" -ForegroundColor Gray
    Write-Host "  ID: $($specificPolicy.Id)" -ForegroundColor Gray
    Write-Host "  Local Admin Enabled: $($specificPolicy.LocalAdminEnabled)" -ForegroundColor Gray
    Write-Host "  Self-Service Enabled: $($specificPolicy.SelfServiceEnabled)" -ForegroundColor Gray
    Write-Host "  Restore Frequency: $($specificPolicy.RestorePointFrequencyInHours) hours" -ForegroundColor Gray
}

# Example 8: Pattern-Based Query
Write-Host "`nExample 8: Finding policies with pattern matching..." -ForegroundColor Green

$labPolicies = Get-LabCloudPCUserSettings -PolicyName "Lab*"
Write-Host "Found $($labPolicies.Count) policies matching 'Lab*'" -ForegroundColor Yellow
$labPolicies | Select-Object DisplayName, LocalAdminEnabled | Format-Table -AutoSize

# Example 9: Update Assignments (Remove and Re-assign)
Write-Host "`nExample 9: Managing assignments..." -ForegroundColor Green

# Remove existing assignments
Remove-LabUserSettingsAssignment -PolicyName "Lab Basic Settings" -RemoveAll
Write-Host "Removed all assignments from Lab Basic Settings" -ForegroundColor Yellow

# Re-assign to different groups
Set-LabUserSettingsAssignment `
    -PolicyName "Lab Basic Settings" `
    -GroupName "Lab Standard Users","W365 Demo Users"
Write-Host "Re-assigned to multiple groups" -ForegroundColor Yellow

# Example 10: Comparison of Different Settings
Write-Host "`nExample 10: Comparing different user settings configurations..." -ForegroundColor Green

$comparisonTable = @()
$allSettings = Get-LabCloudPCUserSettings -All

foreach ($setting in $allSettings) {
    $comparisonTable += [PSCustomObject]@{
        PolicyName = $setting.DisplayName
        LocalAdmin = if($setting.LocalAdminEnabled){"✓"}else{"✗"}
        SelfServiceRestore = if($setting.SelfServiceEnabled){"✓"}else{"✗"}
        RestoreFrequency = "$($setting.RestorePointFrequencyInHours)h"
        UseCase = switch ($true) {
            ($setting.LocalAdminEnabled -and $setting.SelfServiceEnabled) { "Power Users" }
            (-not $setting.LocalAdminEnabled -and $setting.SelfServiceEnabled) { "Standard Users" }
            (-not $setting.LocalAdminEnabled -and -not $setting.SelfServiceEnabled) { "Restricted" }
            default { "Custom" }
        }
    }
}

$comparisonTable | Format-Table -AutoSize

# Example 11: Best Practices Demonstration
Write-Host "`nExample 11: Best practices for user settings..." -ForegroundColor Green

Write-Host "`nRecommended User Settings Configurations:" -ForegroundColor Yellow

Write-Host "`n1. Developer/Power Users:" -ForegroundColor Cyan
Write-Host "   - Local Admin: Enabled" -ForegroundColor Gray
Write-Host "   - Self-Service Restore: Enabled" -ForegroundColor Gray
Write-Host "   - Restore Frequency: 4-6 hours" -ForegroundColor Gray
Write-Host "   - Use Case: Users needing software installation rights" -ForegroundColor Gray

Write-Host "`n2. Standard Business Users:" -ForegroundColor Cyan
Write-Host "   - Local Admin: Disabled" -ForegroundColor Gray
Write-Host "   - Self-Service Restore: Enabled" -ForegroundColor Gray
Write-Host "   - Restore Frequency: 12 hours" -ForegroundColor Gray
Write-Host "   - Use Case: General productivity work" -ForegroundColor Gray

Write-Host "`n3. High-Security Environments:" -ForegroundColor Cyan
Write-Host "   - Local Admin: Disabled" -ForegroundColor Gray
Write-Host "   - Self-Service Restore: Disabled" -ForegroundColor Gray
Write-Host "   - Restore Frequency: 24 hours" -ForegroundColor Gray
Write-Host "   - Use Case: Compliance-heavy industries" -ForegroundColor Gray

Write-Host "`n4. Training/Lab Environments:" -ForegroundColor Cyan
Write-Host "   - Local Admin: Enabled" -ForegroundColor Gray
Write-Host "   - Self-Service Restore: Enabled" -ForegroundColor Gray
Write-Host "   - Restore Frequency: 4 hours" -ForegroundColor Gray
Write-Host "   - Use Case: Testing and experimentation" -ForegroundColor Gray

# Example 12: Cleanup Specific Policies
Write-Host "`nExample 12: Selective cleanup..." -ForegroundColor Green

$cleanup = Read-Host "`nDo you want to clean up demo policies? (yes/no)"

if ($cleanup -eq "yes") {
    Write-Host "`nCleaning up demo resources..." -ForegroundColor Yellow
    
    # Remove user settings assignments first
    $demoSettings = Get-LabCloudPCUserSettings -PolicyName "W365 Demo User Settings"
    if ($demoSettings) {
        Remove-LabUserSettingsAssignment -PolicyId $demoSettings.Id -RemoveAll -Confirm:$false
        Write-Host "Removed user settings assignments" -ForegroundColor Gray
    }
    
    # Remove provisioning policy assignments
    $demoProv = Get-LabCloudPCPolicy -PolicyName "W365 Demo Provisioning"
    if ($demoProv) {
        Remove-LabPolicyAssignment -PolicyId $demoProv.Id -RemoveAll
        Write-Host "Removed provisioning policy assignments" -ForegroundColor Gray
    }
    
    # Wait for assignments to clear
    Start-Sleep -Seconds 5
    
    # Remove licenses
    Remove-LabGroupLicense -GroupName "W365 Demo Users" -RemoveAll -Confirm:$false
    Write-Host "Removed licenses" -ForegroundColor Gray
    
    # Remove users
    Remove-LabUser -UserPrefix "w365demo" -Force
    Write-Host "Removed demo users" -ForegroundColor Gray
    
    # Remove groups
    Remove-LabGroup -GroupName "W365 Demo Users" -Force
    Write-Host "Removed demo group" -ForegroundColor Gray
    
    # Remove policies
    Remove-LabCloudPCUserSettings -PolicyName "W365 Demo User Settings" -Force
    Write-Host "Removed user settings policy" -ForegroundColor Gray
    
    Remove-LabCloudPCPolicy -PolicyName "W365 Demo Provisioning" -Force
    Write-Host "Removed provisioning policy" -ForegroundColor Gray
    
    Write-Host "`nCleanup completed!" -ForegroundColor Green
}
else {
    Write-Host "`nCleanup skipped. Resources remain active." -ForegroundColor Yellow
}

# Example 13: Complete Cleanup (All User Settings)
Write-Host "`nExample 13: Complete cleanup option..." -ForegroundColor Green

$completeCleanup = Read-Host "Do you want to remove ALL user settings policies? (yes/no)"

if ($completeCleanup -eq "yes") {
    Write-Warning "This will remove all user settings policies created in this session!"
    $finalConfirm = Read-Host "Type 'CONFIRM' to proceed"
    
    if ($finalConfirm -eq "CONFIRM") {
        # Remove all lab-related user settings
        Remove-LabCloudPCUserSettings -PolicyName "Lab*" -Force
        Write-Host "Removed all lab user settings policies" -ForegroundColor Yellow
        
        # Remove groups
        Remove-LabGroup -GroupName "Lab Standard Users" -Force -ErrorAction SilentlyContinue
        Remove-LabGroup -GroupName "Lab Admin Users" -Force -ErrorAction SilentlyContinue
        
        Write-Host "Complete cleanup finished!" -ForegroundColor Green
    }
    else {
        Write-Host "Complete cleanup cancelled" -ForegroundColor Yellow
    }
}

# Disconnect
Disconnect-LabGraph

Write-Host "`n=== User Settings Management Examples Completed ===" -ForegroundColor Cyan
Write-Host "`nKey Takeaways:" -ForegroundColor Yellow
Write-Host "1. User settings control the end-user experience on Cloud PCs" -ForegroundColor Gray
Write-Host "2. Local admin access should be carefully controlled based on user role" -ForegroundColor Gray
Write-Host "3. Self-service restore empowers users while reducing admin burden" -ForegroundColor Gray
Write-Host "4. Restore frequency should balance data protection with storage costs" -ForegroundColor Gray
Write-Host "5. Always test user settings in non-production before rolling out" -ForegroundColor Gray
Write-Host "`nFor more information, use Get-Help <function-name> -Full" -ForegroundColor Cyan
