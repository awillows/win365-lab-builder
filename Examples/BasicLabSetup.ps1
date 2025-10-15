<#
.SYNOPSIS
    Basic Windows 365 Lab Setup Example

.DESCRIPTION
    Demonstrates how to create a simple Windows 365 lab environment with users,
    groups, and Cloud PC provisioning policies using the W365LabBuilder module.

.EXAMPLE
    # Run the entire script to create a complete lab
    .\BasicLabSetup.ps1

.NOTES
    This example creates:
    - 10 lab users with random passwords
    - A shared group containing all users
    - A Windows 365 provisioning policy
    - Policy assignment to the group
#>

# Import the Windows 365 Lab Builder module
Import-Module "$PSScriptRoot\..\W365LabBuilder\W365LabBuilder.psd1" -Force

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows 365 Basic Lab Setup Example" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Connect to Microsoft Graph
Write-Host "Step 1: Connecting to Microsoft Graph..." -ForegroundColor Yellow
try {
    Connect-LabGraph
    Write-Host "✅ Connected successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
    exit 1
}

# Step 2: Create complete lab environment
Write-Host "`nStep 2: Creating lab environment..." -ForegroundColor Yellow
Write-Host "  - Creating 10 users with random passwords" -ForegroundColor Gray
Write-Host "  - Creating shared group for all users" -ForegroundColor Gray
Write-Host "  - Creating Windows 365 provisioning policy" -ForegroundColor Gray
Write-Host "  - Assigning policy to group" -ForegroundColor Gray

try {
    $labResult = New-LabEnvironment `
        -UserCount 10 `
        -UserPrefix "basiclab" `
        -CreateSharedGroup `
        -CreateProvisioningPolicies `
        -AssignPolicies

    Write-Host "✅ Lab environment created successfully!" -ForegroundColor Green
    Write-Host "   Users created: $($labResult.Users.Count)" -ForegroundColor White
    Write-Host "   Groups created: $($labResult.Groups.Count)" -ForegroundColor White
    Write-Host "   Policies created: $($labResult.Policies.Count)" -ForegroundColor White
}
catch {
    Write-Error "Failed to create lab environment: $($_.Exception.Message)"
    exit 1
}

# Step 3: Display summary information
Write-Host "`nStep 3: Lab Summary" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow

Write-Host "`n👥 Users:" -ForegroundColor Cyan
$labResult.Users | ForEach-Object {
    Write-Host "   $($_.DisplayName) - $($_.UserPrincipalName)" -ForegroundColor White
}

Write-Host "`n👥 Groups:" -ForegroundColor Cyan
$labResult.Groups | ForEach-Object {
    Write-Host "   $($_.DisplayName) (ID: $($_.Id))" -ForegroundColor White
}

Write-Host "`n🖥️  Cloud PC Policies:" -ForegroundColor Cyan
$labResult.Policies | ForEach-Object {
    Write-Host "   $($_.DisplayName) - Region: $($_.Region)" -ForegroundColor White
}

# Step 4: Export user credentials
Write-Host "`nStep 4: Exporting user credentials..." -ForegroundColor Yellow
if ($labResult.Users[0].Password) {
    $credentialFile = "$PSScriptRoot\BasicLab_Credentials_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $labResult.Users | Select-Object DisplayName, UserPrincipalName, Password | 
        Export-Csv -Path $credentialFile -NoTypeInformation
    
    Write-Host "✅ Credentials exported to: $credentialFile" -ForegroundColor Green
    Write-Host "⚠️  Store this file securely!" -ForegroundColor Red
} else {
    Write-Host "ℹ️  User passwords not returned. To capture passwords, use:" -ForegroundColor Yellow
    Write-Host "   New-LabUser -UserCount 10 -ReturnPasswords" -ForegroundColor Gray
}

# Step 5: Next steps
Write-Host "`nStep 5: Next Steps" -ForegroundColor Yellow
Write-Host "==================" -ForegroundColor Yellow
Write-Host "Your lab is now ready! Here's what you can do next:" -ForegroundColor White
Write-Host ""
Write-Host "1. Monitor Cloud PC provisioning:" -ForegroundColor Cyan
Write-Host "   Get-LabCloudPC -All" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Check user group memberships:" -ForegroundColor Cyan
Write-Host "   Get-LabGroup -GroupName '$($labResult.Groups[0].DisplayName)'" -ForegroundColor Gray
Write-Host ""
Write-Host "3. View policy assignments:" -ForegroundColor Cyan
Write-Host "   Get-LabCloudPCPolicy -PolicyName '$($labResult.Policies[0].DisplayName)'" -ForegroundColor Gray
Write-Host ""
Write-Host "4. When finished, clean up the lab:" -ForegroundColor Cyan
Write-Host "   Remove-LabEnvironment -UserPrefix 'basiclab' -RemovePolicies -RemoveGroups -RemoveUsers -Force" -ForegroundColor Gray
Write-Host ""

Write-Host "🎉 Basic lab setup complete!" -ForegroundColor Green
Write-Host "   Don't forget to disconnect when finished: Disconnect-LabGraph" -ForegroundColor Yellow