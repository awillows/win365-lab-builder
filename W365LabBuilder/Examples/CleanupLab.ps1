<#
.SYNOPSIS
    Example script for cleaning up lab environments using the Windows 365 Lab Builder Module.

.DESCRIPTION
    This script demonstrates how to safely remove lab resources including users,
    groups, and Cloud PC provisioning policies.

.NOTES
    Requires the W365LabBuilder Module to be imported and appropriate Graph permissions.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$UserPrefix = "demo",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Import the W365LabBuilder Module (adjust path as needed)
Import-Module "$PSScriptRoot\..\W365LabBuilder.psd1" -Force

try {
    Write-Host "=== Lab Cleanup Script ===" -ForegroundColor Cyan
    Write-Host ""

    # Step 1: Connect to Microsoft Graph
    Write-Host "Step 1: Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-LabGraph
    Write-Host "✓ Connected successfully" -ForegroundColor Green
    Write-Host ""

    # Step 2: Check what resources exist
    Write-Host "Step 2: Checking existing resources..." -ForegroundColor Yellow
    
    $users = Get-LabUser -UserPrefix $UserPrefix
    $groups = Get-LabGroup -GroupNamePattern "*$UserPrefix*"
    $policies = Get-LabCloudPCPolicy -PolicyNamePattern "*$UserPrefix*"
    
    Write-Host "Found resources to clean up:" -ForegroundColor White
    Write-Host "  Users: $($users.Count)" -ForegroundColor White
    Write-Host "  Groups: $($groups.Count)" -ForegroundColor White  
    Write-Host "  Policies: $($policies.Count)" -ForegroundColor White
    Write-Host ""

    if ($users.Count -eq 0 -and $groups.Count -eq 0 -and $policies.Count -eq 0) {
        Write-Host "✓ No resources found to clean up" -ForegroundColor Green
        return
    }

    # Step 3: Display what will be removed
    if ($users.Count -gt 0) {
        Write-Host "Users to be removed:" -ForegroundColor Yellow
        $users | ForEach-Object { Write-Host "  - $($_.UserPrincipalName)" -ForegroundColor White }
        Write-Host ""
    }

    if ($groups.Count -gt 0) {
        Write-Host "Groups to be removed:" -ForegroundColor Yellow
        $groups | ForEach-Object { Write-Host "  - $($_.DisplayName)" -ForegroundColor White }
        Write-Host ""
    }

    if ($policies.Count -gt 0) {
        Write-Host "Policies to be removed:" -ForegroundColor Yellow
        $policies | ForEach-Object { Write-Host "  - $($_.DisplayName)" -ForegroundColor White }
        Write-Host ""
    }

    # Step 4: Confirm before proceeding (unless -Force is used)
    if (-not $Force) {
        $confirmation = Read-Host "Do you want to proceed with cleanup? (yes/no)"
        if ($confirmation -ne "yes" -and $confirmation -ne "y") {
            Write-Host "Cleanup cancelled by user" -ForegroundColor Yellow
            return
        }
    }

    # Step 5: Perform cleanup
    Write-Host "Step 3: Performing cleanup..." -ForegroundColor Yellow
    
    $cleanupResult = Remove-LabEnvironment -UserPrefix $UserPrefix -RemovePolicies -RemoveGroups -RemoveUsers -Force:$Force
    
    Write-Host "✓ Cleanup completed!" -ForegroundColor Green
    Write-Host "  Policies removed: $($cleanupResult.PoliciesRemoved)" -ForegroundColor White
    Write-Host "  Groups removed: $($cleanupResult.GroupsRemoved)" -ForegroundColor White
    Write-Host "  Users removed: $($cleanupResult.UsersRemoved)" -ForegroundColor White
    Write-Host "  Total time: $($cleanupResult.Duration.TotalSeconds) seconds" -ForegroundColor White
    Write-Host ""

    # Step 6: Verify cleanup
    Write-Host "Step 4: Verifying cleanup..." -ForegroundColor Yellow
    
    $remainingUsers = Get-LabUser -UserPrefix $UserPrefix
    $remainingGroups = Get-LabGroup -GroupNamePattern "*$UserPrefix*"
    $remainingPolicies = Get-LabCloudPCPolicy -PolicyNamePattern "*$UserPrefix*"
    
    $totalRemaining = $remainingUsers.Count + $remainingGroups.Count + $remainingPolicies.Count
    
    if ($totalRemaining -eq 0) {
        Write-Host "✓ Cleanup verification successful - no resources remaining" -ForegroundColor Green
    }
    else {
        Write-Warning "Some resources may still exist:"
        if ($remainingUsers.Count -gt 0) { Write-Host "  Remaining users: $($remainingUsers.Count)" -ForegroundColor Yellow }
        if ($remainingGroups.Count -gt 0) { Write-Host "  Remaining groups: $($remainingGroups.Count)" -ForegroundColor Yellow }
        if ($remainingPolicies.Count -gt 0) { Write-Host "  Remaining policies: $($remainingPolicies.Count)" -ForegroundColor Yellow }
    }

    Write-Host ""
    Write-Host "=== Cleanup Complete ===" -ForegroundColor Green

}
catch {
    Write-Error "Cleanup failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "You may need to manually clean up remaining resources." -ForegroundColor Yellow
}
finally {
    # Always disconnect from Graph when done
    Write-Host ""
    Write-Host "Disconnecting from Microsoft Graph..." -ForegroundColor Yellow
    Disconnect-LabGraph
    Write-Host "✓ Disconnected" -ForegroundColor Green
}