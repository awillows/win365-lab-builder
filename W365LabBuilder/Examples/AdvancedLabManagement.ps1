<#
.SYNOPSIS
    Advanced example showing custom lab configurations and individual resource management.

.DESCRIPTION
    This script demonstrates advanced scenarios like creating custom configurations,
    managing individual resources, and handling specific use cases.

.NOTES
    Requires the W365LabBuilder Module to be imported and appropriate Graph permissions.
#>

# Import the W365LabBuilder Module (adjust path as needed)
Import-Module "$PSScriptRoot\..\W365LabBuilder.psd1" -Force

try {
    Write-Host "=== Advanced Lab Management Example ===" -ForegroundColor Cyan
    Write-Host ""

    # Connect to Microsoft Graph
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-LabGraph
    Write-Host "✓ Connected successfully" -ForegroundColor Green
    Write-Host ""

    # Scenario 1: Create users with custom configuration
    Write-Host "Scenario 1: Creating users with custom configuration..." -ForegroundColor Yellow
    
    $customUsers = New-LabUser -UserCount 3 -UserPrefix "advanced" -StartNumber 100 -Password "CustomPass123!" -UsageLocation "CA"
    Write-Host "✓ Created $($customUsers.Count) users with custom settings" -ForegroundColor Green
    Write-Host ""

    # Scenario 2: Create license and role groups
    Write-Host "Scenario 2: Creating license and role groups..." -ForegroundColor Yellow
    
    $licenseGroup = New-LabGroup -GroupName "Advanced Lab License Group" -Description "License group for advanced lab"
    $roleGroup = New-LabGroup -GroupName "Advanced Lab Role Group" -Description "Role group for advanced lab"
    
    Write-Host "✓ Created license and role groups" -ForegroundColor Green
    Write-Host ""

    # Scenario 3: Add users to groups individually
    Write-Host "Scenario 3: Adding users to groups..." -ForegroundColor Yellow
    
    foreach ($user in $customUsers) {
        Add-LabUserToGroup -UserPrincipalName $user.UserPrincipalName -GroupId $licenseGroup.Id
        Add-LabUserToGroup -UserPrincipalName $user.UserPrincipalName -GroupId $roleGroup.Id
        Write-Host "  Added $($user.UserPrincipalName) to groups" -ForegroundColor White
    }
    Write-Host "✓ All users added to groups" -ForegroundColor Green
    Write-Host ""

    # Scenario 4: Create policies (using Microsoft-hosted network by default)
    Write-Host "Scenario 4: Creating provisioning policies..." -ForegroundColor Yellow
    
    # Optional: Check if Azure network connections are available
    $connections = Get-MgDeviceManagementVirtualEndpointOnPremisesConnection -ErrorAction SilentlyContinue
    
    if ($connections -and $connections.Count -gt 0) {
        Write-Host "  Azure network connections found. Using first connection." -ForegroundColor Cyan
        $useConnection = $true
        $connectionId = $connections[0].Id
    }
    else {
        Write-Host "  No Azure network connections found. Using Microsoft-hosted network (default)." -ForegroundColor Cyan
        $useConnection = $false
    }
    
    $policies = @()
    
    for ($i = 0; $i -lt $customUsers.Count; $i++) {
        $user = $customUsers[$i]
        $username = ($user.UserPrincipalName -split '@')[0]
        
        $policyParams = @{
            PolicyName = "Advanced Policy for $username"
            EnableSingleSignOn = $true
        }
        
        # Optionally add connection ID
        if ($useConnection) {
            $policyParams.OnPremisesConnectionId = $connectionId
        }
        
        $policy = New-LabCloudPCPolicy @policyParams
        $policies += $policy
        
        Write-Host "  Created policy for $username" -ForegroundColor White
    }
    Write-Host "✓ Created $($policies.Count) policies" -ForegroundColor Green
    Write-Host ""

    # Scenario 5: Create individual groups and assign policies
    Write-Host "Scenario 5: Creating individual groups and assigning policies..." -ForegroundColor Yellow
    
    for ($i = 0; $i -lt $customUsers.Count; $i++) {
        $user = $customUsers[$i]
        $policy = $policies[$i]
        $username = ($user.UserPrincipalName -split '@')[0]
        
        # Create individual group
        $individualGroup = New-LabGroup -GroupName "Advanced Group for $username"
        
        # Add user to individual group
        Add-LabUserToGroup -UserPrincipalName $user.UserPrincipalName -GroupId $individualGroup.Id
        
        # Assign policy to group
        Set-LabPolicyAssignment -PolicyId $policy.Id -GroupId $individualGroup.Id
        
        Write-Host "  Created group and assigned policy for $username" -ForegroundColor White
    }
    Write-Host "✓ Individual groups and policy assignments completed" -ForegroundColor Green
    Write-Host ""

    # Scenario 6: Monitor Cloud PC status (simulation)
    Write-Host "Scenario 6: Monitoring Cloud PC status..." -ForegroundColor Yellow
    
    $allCloudPCs = Get-LabCloudPC -All
    $gracePeriodPCs = Get-LabCloudPC -Status "InGracePeriod"
    
    Write-Host "  Total Cloud PCs: $($allCloudPCs.Count)" -ForegroundColor White
    Write-Host "  Cloud PCs in grace period: $($gracePeriodPCs.Count)" -ForegroundColor White
    
    if ($gracePeriodPCs.Count -gt 0) {
        Write-Host "  Found Cloud PCs in grace period - you may want to address these" -ForegroundColor Yellow
        # Example: Stop-LabCloudPCGracePeriod -All -Force
    }
    Write-Host "✓ Cloud PC monitoring completed" -ForegroundColor Green
    Write-Host ""

    # Scenario 7: Display summary
    Write-Host "Scenario 7: Displaying lab summary..." -ForegroundColor Yellow
    
    $allUsers = Get-LabUser -UserPrefix "advanced"
    $allGroups = Get-LabGroup -GroupNamePattern "*advanced*"
    $allPolicies = Get-LabCloudPCPolicy -PolicyNamePattern "*advanced*"
    
    Write-Host ""
    Write-Host "=== Lab Summary ===" -ForegroundColor Cyan
    Write-Host "Users created: $($allUsers.Count)" -ForegroundColor White
    Write-Host "Groups created: $($allGroups.Count)" -ForegroundColor White
    Write-Host "Policies created: $($allPolicies.Count)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "User Details:" -ForegroundColor Cyan
    $allUsers | ForEach-Object { 
        Write-Host "  $($_.UserPrincipalName) - $($_.DisplayName)" -ForegroundColor White
    }
    Write-Host ""
    
    Write-Host "Policy Details:" -ForegroundColor Cyan
    $allPolicies | ForEach-Object {
        Write-Host "  $($_.DisplayName)" -ForegroundColor White
    }
    Write-Host ""

    Write-Host "=== Advanced Lab Setup Complete ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Cleanup command when ready:" -ForegroundColor Yellow
    Write-Host "Remove-LabEnvironment -UserPrefix 'advanced' -RemovePolicies -RemoveGroups -RemoveUsers -Force" -ForegroundColor White

}
catch {
    Write-Error "Advanced lab setup failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Partial cleanup may be needed:" -ForegroundColor Yellow
    Write-Host "Remove-LabEnvironment -UserPrefix 'advanced' -RemovePolicies -RemoveGroups -RemoveUsers -Force" -ForegroundColor White
}
finally {
    # Always disconnect from Graph when done
    Write-Host ""
    Write-Host "Disconnecting from Microsoft Graph..." -ForegroundColor Yellow
    Disconnect-LabGraph
    Write-Host "✓ Disconnected" -ForegroundColor Green
}