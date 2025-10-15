<#
.SYNOPSIS
    Advanced Windows 365 Lab Management Example

.DESCRIPTION
    Demonstrates advanced lab management scenarios including:
    - Multiple user groups with different policies
    - License management
    - User settings policies
    - Regional deployments
    - Monitoring and lifecycle management

.EXAMPLE
    .\AdvancedLabManagement.ps1

.NOTES
    This example showcases enterprise-level lab management capabilities
    including policy customization, monitoring, and cleanup procedures.
#>

# Import the Windows 365 Lab Builder module
Import-Module "$PSScriptRoot\..\W365LabBuilder\W365LabBuilder.psd1" -Force

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Advanced Windows 365 Lab Management Example" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
Connect-LabGraph

Write-Host "`n🏗️  Creating Multi-Tier Lab Environment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Scenario 1: Create developers with administrative access
Write-Host "Scenario 1: Developer Environment (East US)" -ForegroundColor Yellow
$devUsers = New-LabUser -UserCount 5 -UserPrefix "dev" -ReturnPasswords -AddToLicenseGroup

$devGroup = New-LabGroup -GroupName "Lab Developers" -Description "Development team with admin access"
foreach ($user in $devUsers) {
    Add-LabUserToGroup -UserPrincipalName $user.UserPrincipalName -GroupId $devGroup.Id
}

# Create policy for developers (East US region)
$devPolicy = New-LabCloudPCPolicy -PolicyName "Developer Policy - East US" -RegionName "eastus" -EnableSingleSignOn
Set-LabPolicyAssignment -PolicyId $devPolicy.Id -GroupId $devGroup.Id

# Create user settings with admin access for developers
$devSettings = New-LabCloudPCUserSettings -PolicyName "Developer Admin Settings" -EnableLocalAdmin $true -EnableSelfServiceRestore $true -RestorePointFrequencyInHours 8
Set-LabUserSettingsAssignment -PolicyId $devSettings.Id -GroupId $devGroup.Id

Write-Host "✅ Developer environment created:" -ForegroundColor Green
Write-Host "   Users: $($devUsers.Count) (with local admin)" -ForegroundColor White
Write-Host "   Group: $($devGroup.DisplayName)" -ForegroundColor White
Write-Host "   Region: East US" -ForegroundColor White

# Scenario 2: Create trainers with restricted access
Write-Host "`nScenario 2: Trainer Environment (West US)" -ForegroundColor Yellow
$trainerUsers = New-LabUser -UserCount 3 -UserPrefix "trainer" -ReturnPasswords -AddToLicenseGroup

$trainerGroup = New-LabGroup -GroupName "Lab Trainers" -Description "Training staff with standard access"
foreach ($user in $trainerUsers) {
    Add-LabUserToGroup -UserPrincipalName $user.UserPrincipalName -GroupId $trainerGroup.Id
}

# Create policy for trainers (West US region)
$trainerPolicy = New-LabCloudPCPolicy -PolicyName "Trainer Policy - West US" -RegionName "westus2" -EnableSingleSignOn
Set-LabPolicyAssignment -PolicyId $trainerPolicy.Id -GroupId $trainerGroup.Id

# Create restrictive user settings for trainers
$trainerSettings = New-LabCloudPCUserSettings -PolicyName "Trainer Standard Settings" -EnableLocalAdmin $false -EnableSelfServiceRestore $false -RestorePointFrequencyInHours 24
Set-LabUserSettingsAssignment -PolicyId $trainerSettings.Id -GroupId $trainerGroup.Id

Write-Host "✅ Trainer environment created:" -ForegroundColor Green
Write-Host "   Users: $($trainerUsers.Count) (standard access)" -ForegroundColor White
Write-Host "   Group: $($trainerGroup.DisplayName)" -ForegroundColor White
Write-Host "   Region: West US 2" -ForegroundColor White

# Scenario 3: Create students using shared group approach
Write-Host "`nScenario 3: Student Environment (Shared Group)" -ForegroundColor Yellow
$studentLab = New-LabEnvironment -UserCount 25 -UserPrefix "student" -CreateSharedGroup -CreateProvisioningPolicies -AssignPolicies -RegionName "centralus"

Write-Host "✅ Student environment created:" -ForegroundColor Green
Write-Host "   Users: $($studentLab.Users.Count) (shared configuration)" -ForegroundColor White
Write-Host "   Groups: $($studentLab.Groups.Count)" -ForegroundColor White
Write-Host "   Region: Central US" -ForegroundColor White

# License Management
Write-Host "`n💼 Managing Licenses" -ForegroundColor Cyan
Write-Host "===================`n" -ForegroundColor Cyan

# Check available licenses
Write-Host "Checking available licenses..." -ForegroundColor Yellow
$licenses = Get-LabAvailableLicense
Write-Host "Available license SKUs:" -ForegroundColor White
$licenses | ForEach-Object {
    Write-Host "   $($_.SkuPartNumber) - Available: $($_.PrepaidUnits.Enabled - $_.ConsumedUnits)" -ForegroundColor Gray
}

# Assign enterprise licenses to developer group
Write-Host "`nAssigning Enterprise licenses to developers..." -ForegroundColor Yellow
Set-LabGroupLicense -GroupId $devGroup.Id -SkuPartNumber "ENTERPRISEPACK"

# Assign basic licenses to other groups
Set-LabGroupLicense -GroupId $trainerGroup.Id -SkuPartNumber "ENTERPRISEPACK"

Write-Host "`n📊 Environment Monitoring" -ForegroundColor Cyan
Write-Host "=========================`n" -ForegroundColor Cyan

# Monitor Cloud PC deployment
Write-Host "Checking Cloud PC provisioning status..." -ForegroundColor Yellow
Start-Sleep -Seconds 5  # Allow some time for provisioning to begin

$allCloudPCs = Get-LabCloudPC -All
if ($allCloudPCs.Count -gt 0) {
    Write-Host "Cloud PC Status Summary:" -ForegroundColor White
    $statusGroups = $allCloudPCs | Group-Object Status
    foreach ($status in $statusGroups) {
        Write-Host "   $($status.Name): $($status.Count)" -ForegroundColor Gray
    }
} else {
    Write-Host "   No Cloud PCs found yet - provisioning may still be in progress" -ForegroundColor Yellow
}

# Export comprehensive credential report
Write-Host "`n📄 Exporting Credentials" -ForegroundColor Cyan
Write-Host "========================`n" -ForegroundColor Cyan

$allCredentials = @()
$allCredentials += $devUsers | Select-Object @{Name="Role";Expression={"Developer"}}, DisplayName, UserPrincipalName, Password
$allCredentials += $trainerUsers | Select-Object @{Name="Role";Expression={"Trainer"}}, DisplayName, UserPrincipalName, Password
$allCredentials += $studentLab.Users | Select-Object @{Name="Role";Expression={"Student"}}, DisplayName, UserPrincipalName, Password

$credentialFile = "$PSScriptRoot\AdvancedLab_Credentials_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$allCredentials | Export-Csv -Path $credentialFile -NoTypeInformation

Write-Host "✅ Comprehensive credential report exported to:" -ForegroundColor Green
Write-Host "   $credentialFile" -ForegroundColor White

# Display environment summary
Write-Host "`n📋 Lab Environment Summary" -ForegroundColor Cyan
Write-Host "==========================`n" -ForegroundColor Cyan

Write-Host "👨‍💻 Developers (Admin Access):" -ForegroundColor Yellow
$devUsers | ForEach-Object { Write-Host "   $($_.UserPrincipalName)" -ForegroundColor White }

Write-Host "`n👩‍🏫 Trainers (Standard Access):" -ForegroundColor Yellow
$trainerUsers | ForEach-Object { Write-Host "   $($_.UserPrincipalName)" -ForegroundColor White }

Write-Host "`n👩‍🎓 Students (Shared Configuration):" -ForegroundColor Yellow
Write-Host "   $($studentLab.Users.Count) users in shared group: $($studentLab.Groups[0].DisplayName)" -ForegroundColor White

Write-Host "`n🌍 Regional Distribution:" -ForegroundColor Yellow
Write-Host "   East US: Developers ($($devUsers.Count) users)" -ForegroundColor White
Write-Host "   West US 2: Trainers ($($trainerUsers.Count) users)" -ForegroundColor White
Write-Host "   Central US: Students ($($studentLab.Users.Count) users)" -ForegroundColor White

# Advanced management examples
Write-Host "`n🔧 Advanced Management Commands" -ForegroundColor Cyan
Write-Host "==============================`n" -ForegroundColor Cyan

Write-Host "Monitor specific group's Cloud PCs:" -ForegroundColor Yellow
Write-Host "   `$devCloudPCs = Get-LabCloudPC | Where-Object UserPrincipalName -like 'dev*'" -ForegroundColor Gray

Write-Host "`nCheck policy assignments:" -ForegroundColor Yellow
Write-Host "   Get-LabCloudPCPolicy -PolicyName 'Developer Policy - East US'" -ForegroundColor Gray

Write-Host "`nMonitor user settings assignments:" -ForegroundColor Yellow
Write-Host "   Get-LabCloudPCUserSettings -PolicyName 'Developer Admin Settings'" -ForegroundColor Gray

Write-Host "`nEnd grace period for specific users:" -ForegroundColor Yellow
Write-Host "   Stop-LabCloudPCGracePeriod -UserPrincipalName 'dev01@domain.com'" -ForegroundColor Gray

# Cleanup instructions
Write-Host "`n🧹 Cleanup Instructions" -ForegroundColor Cyan
Write-Host "=======================`n" -ForegroundColor Cyan

Write-Host "To clean up this advanced lab environment:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Remove developer environment:" -ForegroundColor White
Write-Host "   Remove-LabEnvironment -UserPrefix 'dev' -RemovePolicies -RemoveGroups -RemoveUsers -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Remove trainer environment:" -ForegroundColor White
Write-Host "   Remove-LabEnvironment -UserPrefix 'trainer' -RemovePolicies -RemoveGroups -RemoveUsers -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Remove student environment:" -ForegroundColor White
Write-Host "   Remove-LabEnvironment -UserPrefix 'student' -RemovePolicies -RemoveGroups -RemoveUsers -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Disconnect from Graph:" -ForegroundColor White
Write-Host "   Disconnect-LabGraph" -ForegroundColor Gray

Write-Host "`n🎉 Advanced lab setup complete!" -ForegroundColor Green
Write-Host "   Total users created: $($devUsers.Count + $trainerUsers.Count + $studentLab.Users.Count)" -ForegroundColor Yellow
Write-Host "   Total groups created: 3" -ForegroundColor Yellow
Write-Host "   Total policies created: 3 provisioning + 2 user settings" -ForegroundColor Yellow