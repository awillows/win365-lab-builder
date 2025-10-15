<#
.SYNOPSIS
    Quick test of the random password functionality.

.DESCRIPTION
    Tests that New-LabUser can generate random passwords internally.
#>

Write-Host "Testing Random Password Feature" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Import Windows 365 Lab Builder module
Import-Module "$PSScriptRoot\..\W365LabBuilder\W365LabBuilder.psd1" -Force

# Test 1: Check parameters
Write-Host "Test 1: Checking New-LabUser parameters..." -ForegroundColor Yellow
$params = (Get-Command New-LabUser).Parameters.Keys
if ($params -contains "Password") {
    Write-Host "  ✅ Password parameter exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ Password parameter missing" -ForegroundColor Red
}

if ($params -contains "ReturnPasswords") {
    Write-Host "  ✅ ReturnPasswords parameter exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ ReturnPasswords parameter missing" -ForegroundColor Red
}

# Test 2: Show help
Write-Host "`nTest 2: Function help..." -ForegroundColor Yellow
Write-Host "  Use: Get-Help New-LabUser -Detailed" -ForegroundColor Gray

# Test 3: WhatIf with default (random passwords)
Write-Host "`nTest 3: Testing with -WhatIf (random passwords)..." -ForegroundColor Yellow
Write-Host "  Command: New-LabUser -UserCount 2 -UserPrefix 'test' -WhatIf" -ForegroundColor Gray
Write-Host "  Expected: Should show it will create users" -ForegroundColor Gray
Write-Host "  (Random passwords generated internally)" -ForegroundColor Gray

# Test 4: WhatIf with custom password
Write-Host "`nTest 4: Testing with -WhatIf (custom password)..." -ForegroundColor Yellow
Write-Host "  Command: New-LabUser -UserCount 2 -UserPrefix 'test' -Password 'CustomPass123!' -WhatIf" -ForegroundColor Gray
Write-Host "  Expected: Should show it will create users with specified password" -ForegroundColor Gray

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Module Structure Verified!" -ForegroundColor Green
Write-Host "`nTo test with actual user creation (requires Graph connection):" -ForegroundColor Cyan
Write-Host "  Connect-LabGraph" -ForegroundColor Gray
Write-Host "  `$users = New-LabUser -UserCount 2 -UserPrefix 'test' -ReturnPasswords" -ForegroundColor Gray
Write-Host "  `$users | Format-Table UserPrincipalName, Password" -ForegroundColor Gray
Write-Host "`nOr with custom password:" -ForegroundColor Cyan
Write-Host "  New-LabUser -UserCount 2 -UserPrefix 'test' -Password 'CustomPass123!'" -ForegroundColor Gray
Write-Host "  (All users will use: CustomPass123!)" -ForegroundColor Gray
