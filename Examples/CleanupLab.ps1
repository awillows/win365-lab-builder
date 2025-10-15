<#
.SYNOPSIS
    Windows 365 Lab Cleanup Example

.DESCRIPTION
    Demonstrates various methods for cleaning up Windows 365 lab environments
    including selective removal, complete cleanup, and verification procedures.

.EXAMPLE
    .\CleanupLab.ps1

.NOTES
    This script shows different cleanup scenarios and safety practices
    for removing lab resources created with the W365LabBuilder module.
#>

# Import the Windows 365 Lab Builder module
Import-Module "$PSScriptRoot\..\W365LabBuilder\W365LabBuilder.psd1" -Force

Write-Host "=======================================" -ForegroundColor Red
Write-Host "Windows 365 Lab Cleanup Example" -ForegroundColor Red
Write-Host "=======================================" -ForegroundColor Red
Write-Host ""
Write-Host "⚠️  WARNING: This script demonstrates lab cleanup procedures" -ForegroundColor Yellow
Write-Host "⚠️  Review all operations before executing in production!" -ForegroundColor Yellow
Write-Host ""

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-LabGraph

Write-Host "`n🔍 Discovery Phase" -ForegroundColor Cyan
Write-Host "==================`n" -ForegroundColor Cyan

# Scenario 1: Discover existing lab resources
Write-Host "Scenario 1: Discovering existing lab resources..." -ForegroundColor Yellow

# Find lab users by prefix
$prefixes = @("demo", "test", "lab", "dev", "trainer", "student")
$foundUsers = @()

foreach ($prefix in $prefixes) {
    Write-Host "Searching for users with prefix '$prefix'..." -ForegroundColor Gray
    try {
        $users = Get-LabUser -UserPrefix $prefix
        if ($users) {
            $foundUsers += $users
            Write-Host "   Found: $($users.Count) users" -ForegroundColor White
        } else {
            Write-Host "   Found: 0 users" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "   Search failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Find lab groups
Write-Host "`nSearching for lab groups..." -ForegroundColor Gray
$labGroups = Get-LabGroup -GroupNamePattern "*Lab*"
if ($labGroups) {
    Write-Host "Found lab groups:" -ForegroundColor White
    $labGroups | ForEach-Object {
        Write-Host "   $($_.DisplayName) (Members: $($_.Members.Count))" -ForegroundColor Gray
    }
} else {
    Write-Host "   No lab groups found" -ForegroundColor Gray
}

# Find Cloud PC policies
Write-Host "`nSearching for Cloud PC policies..." -ForegroundColor Gray
$labPolicies = Get-LabCloudPCPolicy -All | Where-Object DisplayName -like "*Lab*"
if ($labPolicies) {
    Write-Host "Found lab policies:" -ForegroundColor White
    $labPolicies | ForEach-Object {
        Write-Host "   $($_.DisplayName) - $($_.Region)" -ForegroundColor Gray
    }
} else {
    Write-Host "   No lab policies found" -ForegroundColor Gray
}

Write-Host "`n🧪 Cleanup Scenarios" -ForegroundColor Cyan
Write-Host "====================`n" -ForegroundColor Cyan

# Scenario 2: Safe cleanup with confirmation
Write-Host "Scenario 2: Safe cleanup with confirmation prompts..." -ForegroundColor Yellow

if ($foundUsers.Count -gt 0) {
    Write-Host "`nFound $($foundUsers.Count) lab users to potentially remove:" -ForegroundColor White
    $foundUsers | Select-Object -First 5 | ForEach-Object {
        Write-Host "   $($_.DisplayName) - $($_.UserPrincipalName)" -ForegroundColor Gray
    }
    if ($foundUsers.Count -gt 5) {
        Write-Host "   ... and $($foundUsers.Count - 5) more" -ForegroundColor Gray
    }
    
    Write-Host "`nTo remove users with confirmation prompts:" -ForegroundColor Cyan
    Write-Host "   Remove-LabUser -UserPrefix 'demo'  # Interactive prompts" -ForegroundColor Gray
    Write-Host "   Remove-LabUser -UserPrefix 'demo' -Force  # Skip prompts" -ForegroundColor Gray
} else {
    Write-Host "✅ No lab users found to clean up" -ForegroundColor Green
}

# Scenario 3: Complete environment cleanup
Write-Host "`nScenario 3: Complete environment cleanup..." -ForegroundColor Yellow
Write-Host "This removes users, groups, and policies for a specific prefix:" -ForegroundColor White
Write-Host ""
Write-Host "Example commands:" -ForegroundColor Cyan
Write-Host "   # Preview what would be removed (safe)" -ForegroundColor Gray
Write-Host "   Remove-LabEnvironment -UserPrefix 'demo' -RemoveUsers -RemoveGroups -RemovePolicies -WhatIf" -ForegroundColor Gray
Write-Host ""
Write-Host "   # Actually remove everything (DESTRUCTIVE)" -ForegroundColor Gray
Write-Host "   Remove-LabEnvironment -UserPrefix 'demo' -RemoveUsers -RemoveGroups -RemovePolicies -Force" -ForegroundColor Gray

# Scenario 4: Selective cleanup
Write-Host "`nScenario 4: Selective cleanup operations..." -ForegroundColor Yellow
Write-Host "Remove only specific resource types:" -ForegroundColor White
Write-Host ""
Write-Host "Remove only users (keep groups and policies):" -ForegroundColor Cyan
Write-Host "   Remove-LabEnvironment -UserPrefix 'demo' -RemoveUsers -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "Remove only policies (keep users and groups):" -ForegroundColor Cyan
Write-Host "   Remove-LabEnvironment -UserPrefix 'demo' -RemovePolicies -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "Remove individual resources by name:" -ForegroundColor Cyan
Write-Host "   Remove-LabUser -UserPrincipalName 'demo01@domain.com' -Force" -ForegroundColor Gray
Write-Host "   Remove-LabGroup -GroupName 'Demo Lab Group' -Force" -ForegroundColor Gray
Write-Host "   Remove-LabCloudPCPolicy -PolicyName 'Demo Policy' -Force" -ForegroundColor Gray

# Scenario 5: Cloud PC lifecycle management
Write-Host "`nScenario 5: Cloud PC lifecycle management..." -ForegroundColor Yellow

# Check for Cloud PCs in grace period
$gracePeriodPCs = Get-LabCloudPC -Status "InGracePeriod"
if ($gracePeriodPCs.Count -gt 0) {
    Write-Host "Found $($gracePeriodPCs.Count) Cloud PCs in grace period:" -ForegroundColor White
    $gracePeriodPCs | ForEach-Object {
        Write-Host "   $($_.UserPrincipalName) - Status: $($_.Status)" -ForegroundColor Gray
    }
    
    Write-Host "`nTo end grace period:" -ForegroundColor Cyan
    Write-Host "   Stop-LabCloudPCGracePeriod -All -Force" -ForegroundColor Gray
    Write-Host "   # Or for specific user:" -ForegroundColor Gray
    Write-Host "   Stop-LabCloudPCGracePeriod -UserPrincipalName 'demo01@domain.com'" -ForegroundColor Gray
} else {
    Write-Host "✅ No Cloud PCs in grace period found" -ForegroundColor Green
}

Write-Host "`n🛡️  Safety Best Practices" -ForegroundColor Cyan
Write-Host "=========================`n" -ForegroundColor Cyan

Write-Host "1. Always use -WhatIf first:" -ForegroundColor Yellow
Write-Host "   Remove-LabEnvironment -UserPrefix 'demo' -RemoveAll -WhatIf" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Export data before cleanup:" -ForegroundColor Yellow
Write-Host "   `$users = Get-LabUser -UserPrefix 'demo'" -ForegroundColor Gray
Write-Host "   `$users | Export-Csv 'backup-users.csv' -NoTypeInformation" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Test with small batches first:" -ForegroundColor Yellow
Write-Host "   Remove-LabUser -UserPrincipalName 'test01@domain.com' -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Verify removal:" -ForegroundColor Yellow
Write-Host "   Get-LabUser -UserPrefix 'demo'  # Should return empty" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Check dependencies:" -ForegroundColor Yellow
Write-Host "   Get-LabGroup -GroupName 'Demo Group'  # Check group membership" -ForegroundColor Gray
Write-Host "   Get-LabCloudPCPolicy -PolicyName 'Demo Policy'  # Check assignments" -ForegroundColor Gray

Write-Host "`n🔄 Cleanup Automation Example" -ForegroundColor Cyan
Write-Host "=============================`n" -ForegroundColor Cyan

Write-Host "Here's a complete cleanup automation script:" -ForegroundColor Yellow
Write-Host ""
$cleanupScript = @'
# Automated lab cleanup function
function Remove-CompleteLab {
    param(
        [string]$UserPrefix,
        [switch]$WhatIf
    )
    
    Write-Host "Starting cleanup for prefix: $UserPrefix" -ForegroundColor Yellow
    
    # Backup before cleanup
    if (-not $WhatIf) {
        $backupFile = "backup_${UserPrefix}_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $users = Get-LabUser -UserPrefix $UserPrefix
        if ($users) {
            $users | Export-Csv $backupFile -NoTypeInformation
            Write-Host "Backup saved to: $backupFile" -ForegroundColor Green
        }
    }
    
    # End Cloud PC grace periods
    $gracePCs = Get-LabCloudPC -UserPrefix $UserPrefix -Status "InGracePeriod"
    if ($gracePCs -and -not $WhatIf) {
        Stop-LabCloudPCGracePeriod -UserPrefix $UserPrefix -Force
    }
    
    # Remove environment
    $params = @{
        UserPrefix = $UserPrefix
        RemoveUsers = $true
        RemoveGroups = $true  
        RemovePolicies = $true
        Force = (-not $WhatIf)
    }
    if ($WhatIf) { $params.WhatIf = $true }
    
    Remove-LabEnvironment @params
    
    Write-Host "Cleanup completed for prefix: $UserPrefix" -ForegroundColor Green
}

# Usage examples:
# Remove-CompleteLab -UserPrefix "demo" -WhatIf    # Preview
# Remove-CompleteLab -UserPrefix "demo"            # Execute
'@

Write-Host $cleanupScript -ForegroundColor Gray

Write-Host "`n📊 Verification Commands" -ForegroundColor Cyan
Write-Host "=======================`n" -ForegroundColor Cyan

Write-Host "After cleanup, verify removal with these commands:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Check users are gone:" -ForegroundColor Cyan
Write-Host "   Get-LabUser -UserPrefix 'demo'" -ForegroundColor Gray
Write-Host ""
Write-Host "Check groups are gone:" -ForegroundColor Cyan
Write-Host "   Get-LabGroup -GroupNamePattern '*Demo*'" -ForegroundColor Gray
Write-Host ""
Write-Host "Check policies are gone:" -ForegroundColor Cyan
Write-Host "   Get-LabCloudPCPolicy -All | Where-Object DisplayName -like '*Demo*'" -ForegroundColor Gray
Write-Host ""
Write-Host "Check Cloud PCs are removed:" -ForegroundColor Cyan
Write-Host "   Get-LabCloudPC -All | Where-Object UserPrincipalName -like 'demo*'" -ForegroundColor Gray

Write-Host "`n✅ Cleanup Examples Complete" -ForegroundColor Green
Write-Host "============================`n" -ForegroundColor Green

Write-Host "This script provided examples of:" -ForegroundColor White
Write-Host "  ✓ Resource discovery" -ForegroundColor Gray
Write-Host "  ✓ Safe cleanup with confirmations" -ForegroundColor Gray
Write-Host "  ✓ Complete environment removal" -ForegroundColor Gray
Write-Host "  ✓ Selective cleanup operations" -ForegroundColor Gray
Write-Host "  ✓ Cloud PC lifecycle management" -ForegroundColor Gray
Write-Host "  ✓ Safety best practices" -ForegroundColor Gray
Write-Host "  ✓ Automation patterns" -ForegroundColor Gray
Write-Host "  ✓ Verification procedures" -ForegroundColor Gray
Write-Host ""
Write-Host "Remember: Always test cleanup operations with -WhatIf first!" -ForegroundColor Yellow

Write-Host "`nDisconnect from Graph when finished:" -ForegroundColor Cyan
Write-Host "   Disconnect-LabGraph" -ForegroundColor Gray