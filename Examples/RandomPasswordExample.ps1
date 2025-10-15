<#
.SYNOPSIS
    Example demonstrating random password generation for lab users.

.DESCRIPTION
    Shows how to create lab users with random passwords (default behavior)
    or with a default password when needed. Also demonstrates how to capture
    and export user credentials securely.

.NOTES
    New-LabUser generates random passwords by default for improved security.
    Use -Password parameter to specify a custom password.
#>

# Import the Windows 365 Lab Builder module
Import-Module "$PSScriptRoot\..\W365LabBuilder\W365LabBuilder.psd1" -Force

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-LabGraph -UseDeviceCode

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Example 1: Random Passwords (Default)" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

# Create 5 users with random passwords - credentials are NOT returned by default
Write-Host "Creating 5 users with random passwords..." -ForegroundColor Cyan
$users = New-LabUser -UserCount 5 -UserPrefix "demo" -AddToLicenseGroup

Write-Host "`nCreated users (passwords not captured):" -ForegroundColor Green
$users | Format-Table DisplayName, UserPrincipalName

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Example 2: Random Passwords WITH Capture" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

# Create users and capture credentials for export
Write-Host "Creating 5 users with random passwords and capturing credentials..." -ForegroundColor Cyan
$userCredentials = New-LabUser -UserCount 5 -UserPrefix "train" -AddToLicenseGroup -ReturnPasswords

Write-Host "`nUser credentials captured:" -ForegroundColor Green
$userCredentials | Format-Table UserPrincipalName, Username, Password

# Export credentials to CSV (store securely!)
$credentialFile = "$PSScriptRoot\UserCredentials_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$userCredentials | Export-Csv -Path $credentialFile -NoTypeInformation
Write-Host "`nCredentials exported to: $credentialFile" -ForegroundColor Green
Write-Host "⚠️  IMPORTANT: Store this file securely and delete when no longer needed!" -ForegroundColor Red

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Example 3: Custom Password" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

# Create users with custom password
Write-Host "Creating 5 users with custom password..." -ForegroundColor Cyan
$defaultUsers = New-LabUser -UserCount 5 -UserPrefix "custom" -Password "CustomLab2025!!" -AddToLicenseGroup

Write-Host "`nCreated users with custom password:" -ForegroundColor Green
$defaultUsers | Format-Table DisplayName, UserPrincipalName
Write-Host "Password for all users: CustomLab2025!!" -ForegroundColor Yellow

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Example 4: Large Training Batch" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

# Create larger batch for a training event
Write-Host "Creating 50 users for training event with random passwords..." -ForegroundColor Cyan
$trainingUsers = New-LabUser -UserCount 50 -UserPrefix "train" -AddToLicenseGroup -ReturnPasswords

# Export to CSV for distribution
$trainingCredFile = "$PSScriptRoot\TrainingLab_UserCredentials_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$trainingUsers | Export-Csv -Path $trainingCredFile -NoTypeInformation

Write-Host "`n✅ Created $($trainingUsers.Count) training users" -ForegroundColor Green
Write-Host "📄 Credentials saved to: $trainingCredFile" -ForegroundColor Cyan
Write-Host "`nSample credentials:" -ForegroundColor Yellow
$trainingUsers | Select-Object -First 3 | Format-Table UserPrincipalName, Username, Password

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Comparison: Random vs Default Passwords" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

Write-Host "Random Passwords (Default):" -ForegroundColor Cyan
Write-Host "  ✅ Unique password per user" -ForegroundColor Green
Write-Host "  ✅ 16 characters with high entropy" -ForegroundColor Green
Write-Host "  ✅ Meets Azure AD complexity requirements" -ForegroundColor Green
Write-Host "  ✅ Better security for production/training" -ForegroundColor Green
Write-Host "  ⚠️  Must use -ReturnPasswords to capture" -ForegroundColor Yellow
Write-Host "  Example: New-LabUser -UserCount 10 -ReturnPasswords" -ForegroundColor Gray

Write-Host "`nCustom Password (-Password):" -ForegroundColor Cyan
Write-Host "  📌 Same password for all users" -ForegroundColor Yellow
Write-Host "  📌 Easy to remember and communicate" -ForegroundColor Yellow
Write-Host "  📌 Good for demos or short-lived labs" -ForegroundColor Yellow
Write-Host "  ⚠️  Less secure for extended use" -ForegroundColor Red
Write-Host "  Example: New-LabUser -UserCount 10 -Password 'YourPassword123!'" -ForegroundColor Gray

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Best Practices" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

Write-Host "1. Use random passwords (default) for:" -ForegroundColor Cyan
Write-Host "   - Production training environments" -ForegroundColor White
Write-Host "   - Multi-day workshops" -ForegroundColor White
Write-Host "   - Any scenario where security matters" -ForegroundColor White

Write-Host "`n2. Use -ReturnPasswords to capture credentials:" -ForegroundColor Cyan
Write-Host "   `$creds = New-LabUser -UserCount 50 -ReturnPasswords" -ForegroundColor Gray
Write-Host "   `$creds | Export-Csv -Path 'credentials.csv' -NoTypeInformation" -ForegroundColor Gray

Write-Host "`n3. Secure credential storage:" -ForegroundColor Cyan
Write-Host "   - Export to encrypted location" -ForegroundColor White
Write-Host "   - Use Azure Key Vault for production" -ForegroundColor White
Write-Host "   - Delete credential files after distribution" -ForegroundColor White
Write-Host "   - Use password manager for tracking" -ForegroundColor White

Write-Host "`n4. Use default password only for:" -ForegroundColor Cyan
Write-Host "   - Quick demos (<1 hour)" -ForegroundColor White
Write-Host "   - Testing scenarios" -ForegroundColor White
Write-Host "   - Conference booth demos" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Sample Commands" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

Write-Host "# Random passwords (recommended):" -ForegroundColor Cyan
Write-Host "`$users = New-LabUser -UserCount 50 -UserPrefix 'workshop' -ReturnPasswords" -ForegroundColor Gray
Write-Host "`$users | Export-Csv 'WorkshopCredentials.csv' -NoTypeInformation" -ForegroundColor Gray

Write-Host "`n# Default password (quick demo):" -ForegroundColor Cyan
Write-Host "New-LabUser -UserCount 10 -UserPrefix 'demo' -UseDefaultPassword" -ForegroundColor Gray

Write-Host "`n# With full environment setup:" -ForegroundColor Cyan
Write-Host "`$creds = New-LabUser -UserCount 100 -UserPrefix 'lab' -AddToLicenseGroup -AddToRoleGroup -ReturnPasswords" -ForegroundColor Gray

Write-Host "`n✅ Examples completed!" -ForegroundColor Green
Write-Host "⚠️  Remember to securely store or delete any credential CSV files!" -ForegroundColor Red
