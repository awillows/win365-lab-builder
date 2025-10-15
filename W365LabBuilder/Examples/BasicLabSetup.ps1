<#
.SYNOPSIS
    Example script demonstrating basic lab setup using the Windows 365 Lab Builder Module.

.DESCRIPTION
    This script shows how to create a complete lab environment with users, groups, 
    and Cloud PC provisioning policies using the Windows 365 Lab Builder Module.

.NOTES
    Requires the W365LabBuilder Module to be imported and appropriate Graph permissions.
#>

# Import the W365LabBuilder Module (adjust path as needed)
Import-Module "$PSScriptRoot\..\W365LabBuilder.psd1" -Force

try {
    Write-Host "=== Windows 365 Lab Setup Example ===" -ForegroundColor Cyan
    Write-Host ""

    # Step 1: Connect to Microsoft Graph
    Write-Host "Step 1: Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-LabGraph
    Write-Host "✓ Connected successfully" -ForegroundColor Green
    Write-Host ""

    # Step 2: Create a complete lab environment
    Write-Host "Step 2: Creating lab environment..." -ForegroundColor Yellow
    Write-Host "Using Microsoft-hosted network (default)" -ForegroundColor Cyan
    
    $labConfig = @{
        UserCount = 5
        UserPrefix = "demo"
        CreateIndividualGroups = $false
        CreateSharedGroup = $true
        CreateProvisioningPolicies = $true
        AssignPolicies = $true
    }
    
    # Optional: Add Azure network connection if you have one configured
    # $connection = Get-MgDeviceManagementVirtualEndpointOnPremisesConnection | Select-Object -First 1
    # if ($connection) {
    #     $labConfig.OnPremisesConnectionId = $connection.Id
    #     Write-Host "Using Azure network connection: $($connection.DisplayName)" -ForegroundColor Cyan
    # }

    $result = New-LabEnvironment @labConfig
    
    Write-Host "✓ Lab environment created successfully!" -ForegroundColor Green
    Write-Host "  Users created: $($result.Users.Count)" -ForegroundColor White
    Write-Host "  Groups created: $($result.Groups.Count)" -ForegroundColor White
    Write-Host "  Policies created: $($result.Policies.Count) (single shared policy)" -ForegroundColor White
    if ($result.Assignments) {
        Write-Host "  Policy assignments: $($result.Assignments.Count)" -ForegroundColor White
    }
    Write-Host "  Total time: $($result.Duration.TotalSeconds) seconds" -ForegroundColor White
    Write-Host ""

    # Step 3: Verify the created resources
    Write-Host "Step 3: Verifying created resources..." -ForegroundColor Yellow
    
    $users = Get-LabUser -UserPrefix "demo"
    $groups = Get-LabGroup -GroupNamePattern "*demo*"
    $policies = Get-LabCloudPCPolicy -PolicyNamePattern "*demo*"
    
    Write-Host "✓ Verification complete:" -ForegroundColor Green
    Write-Host "  Users found: $($users.Count)" -ForegroundColor White
    Write-Host "  Groups found: $($groups.Count)" -ForegroundColor White
    Write-Host "  Policies found: $($policies.Count)" -ForegroundColor White
    Write-Host ""

    # Display some details
    Write-Host "Created Users:" -ForegroundColor Cyan
    $users | ForEach-Object { Write-Host "  - $($_.UserPrincipalName)" -ForegroundColor White }
    Write-Host ""
    
    Write-Host "Created Groups:" -ForegroundColor Cyan
    $groups | ForEach-Object { Write-Host "  - $($_.DisplayName)" -ForegroundColor White }
    Write-Host ""
    
    Write-Host "Policy Assignments:" -ForegroundColor Cyan
    if ($policies.Count -gt 0 -and $groups.Count -gt 0) {
        $policy = $policies[0]
        Write-Host "  Policy: $($policy.DisplayName)" -ForegroundColor White
        Write-Host "  Assigned to groups:" -ForegroundColor White
        foreach ($group in $groups) {
            Write-Host "    - $($group.DisplayName)" -ForegroundColor White
        }
    } else {
        Write-Host "  No assignments to display" -ForegroundColor Gray
    }
    Write-Host ""

    Write-Host "=== Lab Setup Complete ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Users can now log in with password: Lab2024!!" -ForegroundColor White
    Write-Host "2. Cloud PC provisioning will begin automatically" -ForegroundColor White
    Write-Host "3. Use Remove-LabEnvironment to clean up when done" -ForegroundColor White

}
catch {
    Write-Error "Lab setup failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Cleanup recommendation:" -ForegroundColor Yellow
    Write-Host "Run: Remove-LabEnvironment -UserPrefix 'demo' -RemovePolicies -RemoveGroups -RemoveUsers -Force" -ForegroundColor White
}
finally {
    # Always disconnect from Graph when done
    Write-Host ""
    Write-Host "Disconnecting from Microsoft Graph..." -ForegroundColor Yellow
    Disconnect-LabGraph
    Write-Host "✓ Disconnected" -ForegroundColor Green
}