<#
.SYNOPSIS
    Examples for creating Windows 365 Cloud PC provisioning policies.

.DESCRIPTION
    This script demonstrates different ways to create and configure Windows 365
    provisioning policies. By default, policies use Microsoft-hosted network.
    Optionally, you can specify an Azure network connection for Azure network connectivity.

.NOTES
    Requires:
    - Microsoft Graph permissions: CloudPC.ReadWrite.All
    - Azure network connection (optional - only if using Azure network connectivity)
#>

# Import the module
Import-Module "$PSScriptRoot\..\W365LabBuilder.psd1" -Force

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-LabGraph

Write-Host "`n=== Windows 365 Provisioning Policy Examples ===" -ForegroundColor Cyan

# Example 1: Create Policy with Microsoft-Hosted Network (Default - Simplest)
Write-Host "`nExample 1: Creating policy with Microsoft-hosted network (default)..." -ForegroundColor Green

$policy1 = New-LabCloudPCPolicy -PolicyName "Lab Policy - Microsoft Hosted"

Write-Host "✓ Created policy: $($policy1.DisplayName)" -ForegroundColor Yellow
Write-Host "  ID: $($policy1.Id)" -ForegroundColor Gray
Write-Host "  Network: Microsoft-hosted (default)" -ForegroundColor Gray

# Example 2: List Available Azure Network Connections (Optional)
# Example 2: List Available Azure Network Connections (Optional)
Write-Host "`nExample 2: Discovering available Azure network connections (optional)..." -ForegroundColor Green

$connections = Get-MgDeviceManagementVirtualEndpointOnPremisesConnection -ErrorAction SilentlyContinue

if ($connections) {
    Write-Host "Found $($connections.Count) Azure network connection(s):" -ForegroundColor Yellow
    $connections | ForEach-Object {
        Write-Host "  Name: $($_.DisplayName)" -ForegroundColor White
        Write-Host "    ID: $($_.Id)" -ForegroundColor Gray
        Write-Host "    Type: $($_.Type)" -ForegroundColor Gray
        Write-Host "    Health Status: $($_.HealthCheckStatus)" -ForegroundColor Gray
        Write-Host ""
    }
}
else {
    Write-Host "No Azure network connections found." -ForegroundColor Yellow
    Write-Host "This is fine - you can still create policies using Microsoft-hosted network (default)." -ForegroundColor Cyan
}

# Example 3: Create Policy with Azure Network Connection (Optional)
Write-Host "`nExample 3: Creating policy with Azure network connection..." -ForegroundColor Green

if ($connections -and $connections.Count -gt 0) {
    $connection = $connections[0]
    
    $policy2 = New-LabCloudPCPolicy `
        -PolicyName "Lab Policy - Azure Network" `
        -Description "Policy using Azure network connection" `
        -OnPremisesConnectionId $connection.Id `
        -EnableSingleSignOn
    
    Write-Host "✓ Created policy: $($policy2.DisplayName)" -ForegroundColor Yellow
    Write-Host "  ID: $($policy2.Id)" -ForegroundColor Gray
    Write-Host "  Connection: $($connection.DisplayName)" -ForegroundColor Gray
}
else {
    Write-Host "⚠ Skipped: No Azure network connections available" -ForegroundColor Yellow
    Write-Host "  Use Microsoft-hosted network instead (see Example 1)" -ForegroundColor Cyan
}

# Example 4: Create Policy with Custom Image
Write-Host "`nExample 4: Creating policy with custom image settings..." -ForegroundColor Green

$policy3 = New-LabCloudPCPolicy `
    -PolicyName "Lab Policy - Custom Image" `
    -Description "Policy with custom Windows 11 image" `
    -ImageId "microsoftwindowsdesktop_windows-ent-cpc_win11-23h2-ent-cpc-m365" `
    -ImageDisplayName "Windows 11 23H2 Enterprise + M365" `
    -ImageType "gallery" `
    -Locale "en-US"

Write-Host "✓ Created policy with custom image: $($policy3.DisplayName)" -ForegroundColor Yellow

# Example 5: Create Policies with Different Locale Settings
Write-Host "`nExample 5: Creating policies with different locale settings..." -ForegroundColor Green

$locales = @{
    "English US" = "en-US"
    "German" = "de-DE"
    "French" = "fr-FR"
    "Spanish" = "es-ES"
}

foreach ($name in $locales.Keys) {
    $locale = $locales[$name]
    
    try {
        $policy = New-LabCloudPCPolicy `
            -PolicyName "Lab Policy - $name" `
            -Description "Policy with $name locale" `
            -Locale $locale
        
        Write-Host "  ✓ Created $name policy: $($policy.DisplayName)" -ForegroundColor White
        Write-Host "    Locale: $locale" -ForegroundColor Gray
    }
    catch {
        Write-Host "  ✗ Failed to create $name policy: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Example 6: Create Policy with Single Sign-On
Write-Host "`nExample 6: Creating policy with single sign-on enabled..." -ForegroundColor Green

$policySSO = New-LabCloudPCPolicy `
    -PolicyName "Lab Policy - SSO Enabled" `
    -Description "Policy with SSO for seamless authentication" `
    -EnableSingleSignOn

Write-Host "✓ Created policy with SSO: $($policySSO.DisplayName)" -ForegroundColor Yellow

# Example 7: List All Created Policies
Write-Host "`nExample 7: Listing all 'Lab Policy' policies..." -ForegroundColor Green

$allPolicies = Get-LabCloudPCPolicy -PolicyNamePattern "Lab Policy*"

Write-Host "Found $($allPolicies.Count) policies:" -ForegroundColor Yellow
$allPolicies | ForEach-Object {
    Write-Host "  - $($_.DisplayName)" -ForegroundColor White
    Write-Host "    ID: $($_.Id)" -ForegroundColor Gray
}

# Example 8: Complete Setup with Policy Assignment
Write-Host "`nExample 8: Complete setup with policy assignment..." -ForegroundColor Green

# Create test user
$testUser = New-LabUser -UserCount 1 -UserPrefix "w365test" -StartNumber 999

# Create group
$testGroup = New-LabGroup -GroupName "W365 Test Group" -Description "Test group for policy assignment"

# Add user to group
Add-LabUserToGroup -UserPrincipalName $testUser[0].UserPrincipalName -GroupId $testGroup.Id

# Create policy (uses Microsoft-hosted network by default)
$testPolicy = New-LabCloudPCPolicy -PolicyName "W365 Test Policy"

# Assign policy to group
Set-LabPolicyAssignment -PolicyId $testPolicy.Id -GroupId $testGroup.Id

Write-Host "✓ Complete setup finished!" -ForegroundColor Green
Write-Host "  User: $($testUser[0].UserPrincipalName)" -ForegroundColor White
Write-Host "  Group: $($testGroup.DisplayName)" -ForegroundColor White
Write-Host "  Policy: $($testPolicy.DisplayName)" -ForegroundColor White
Write-Host "  Network: Microsoft-hosted (default)" -ForegroundColor White

Write-Host "`n=== Examples Complete ===" -ForegroundColor Cyan
Write-Host "`nKey Takeaways:" -ForegroundColor Yellow
Write-Host "1. By default, policies use Microsoft-hosted network (no setup required)" -ForegroundColor White
Write-Host "2. Optionally specify -OnPremisesConnectionId for Azure network connectivity" -ForegroundColor White
Write-Host "3. Use Get-MgDeviceManagementVirtualEndpointOnPremisesConnection to find connection IDs" -ForegroundColor White
Write-Host "4. Microsoft-hosted network is the simplest and recommended for most lab scenarios" -ForegroundColor White

# Cleanup reminder
Write-Host "`nTo clean up test resources:" -ForegroundColor Yellow
Write-Host "Remove-LabUser -UserPrefix 'w365test' -Force" -ForegroundColor Gray
Write-Host "Remove-LabGroup -GroupNamePattern 'W365 Test*' -Force" -ForegroundColor Gray
Write-Host "Remove-LabCloudPCPolicy -PolicyNamePattern 'Lab Policy*' -Force" -ForegroundColor Gray

# Disconnect
Write-Host "`nDisconnecting from Microsoft Graph..." -ForegroundColor Cyan
Disconnect-LabGraph
