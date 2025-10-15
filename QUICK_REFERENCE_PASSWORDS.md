# Quick Reference: New-LabUser Password Options

## TL;DR

```powershell
# Random passwords (DEFAULT - RECOMMENDED):
$users = New-LabUser -UserCount 50 -ReturnPasswords
$users | Export-Csv "credentials.csv"

# Custom password:
New-LabUser -UserCount 10 -Password "CustomPass123!"
# Password: CustomPass123!!
```

## Decision Tree

```
Need passwords for distribution?
  │
  ├─ YES → Use -ReturnPasswords
  │        $users = New-LabUser -UserCount 50 -ReturnPasswords
  │        $users | Export-Csv "credentials.csv"
  │
  └─ NO  → Is this a quick demo (<1 hour)?
           │
           ├─ YES → Use -Password parameter
           │        New-LabUser -UserCount 10 -Password "DemoPass123!"
           │        (Everyone uses: DemoPass123!!)
           │
           └─ NO  → ⚠️ Don't create users without capturing passwords!
                    Use -ReturnPasswords
```

## Common Commands

### Training Event (50-200 users)
```powershell
$creds = New-LabUser -UserCount 100 -UserPrefix "workshop" -AddToLicenseGroup -ReturnPasswords
$creds | Export-Csv "WorkshopCredentials.csv" -NoTypeInformation
```

### Quick Demo (5-10 users)
```powershell
New-LabUser -UserCount 10 -UserPrefix "demo" -Password "DemoPass123!"
# All users: DemoPass123!
```

### With Full Environment
```powershell
# Create users with passwords
$users = New-LabUser -UserCount 50 -UserPrefix "lab" -ReturnPasswords
$users | Export-Csv "credentials.csv"

# Create environment
New-LabEnvironment -UserCount 50 -UserPrefix "lab" -CreateSharedGroup -CreateProvisioningPolicies -AssignPolicies
```

## Output Formats

### With -ReturnPasswords
```
UserPrincipalName          DisplayName      Password         Username
-----------------          -----------      --------         --------
user001@contoso.com        Lab User 001     Qw45$#HnPx92@k   user001
user002@contoso.com        Lab User 002     Kb$8Tr#6Yx@4Mn   user002
```

### Without -ReturnPasswords
```
DisplayName            UserPrincipalName         Id
-----------            -----------------         --
Lab User 001           user001@contoso.com       guid-here
Lab User 002           user002@contoso.com       guid-here

⚠️ WARNING: Random passwords generated but not captured!
```

## Parameters Quick Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-UserCount` | Int | 1 | Number of users to create |
| `-UserPrefix` | String | "lu" | Username prefix |
| `-Password` | String | Random | Use specific password for all users |
| `-ReturnPasswords` | Switch | Off | Return credentials with passwords |
| `-AddToLicenseGroup` | Switch | Off | Add to license group |
| `-AddToRoleGroup` | Switch | Off | Add to role group |

## Password Characteristics

### Random (Default)
- ✅ Length: 16 characters
- ✅ Uppercase: 2+ (A-Z)
- ✅ Lowercase: 2+ (a-z)
- ✅ Numbers: 2+ (2-9)
- ✅ Symbols: 2+ (!@#$%^&*)
- ✅ Unique per user
- ✅ High entropy

### Custom (`-Password`)
- Password: **Your specified password**
- Same for all users
- Easy to communicate
- Good for short demos only

## Common Mistakes

### ❌ Mistake 1: Not Capturing Passwords
```powershell
# BAD - Random passwords generated but lost!
New-LabUser -UserCount 50
```
**Fix:**
```powershell
# GOOD - Capture passwords
$users = New-LabUser -UserCount 50 -ReturnPasswords
```

### ❌ Mistake 2: Using Same Password for Training
```powershell
# BAD - Security risk for multi-day event
New-LabUser -UserCount 100 -Password "SamePassword123!"
```
**Fix:**
```powershell
# GOOD - Random passwords for training
$users = New-LabUser -UserCount 100 -ReturnPasswords
$users | Export-Csv "credentials.csv"
```

### ❌ Mistake 3: Not Exporting Credentials
```powershell
# BAD - Credentials only in memory
$users = New-LabUser -UserCount 50 -ReturnPasswords
# If session closes, passwords are lost!
```
**Fix:**
```powershell
# GOOD - Export immediately
$users = New-LabUser -UserCount 50 -ReturnPasswords
$users | Export-Csv "credentials.csv" -NoTypeInformation
```

## Security Guidelines

| Scenario | Use | Password Type |
|----------|-----|---------------|
| Multi-day training | `-ReturnPasswords` | Random ✅ |
| Workshop (4+ hours) | `-ReturnPasswords` | Random ✅ |
| Conference demo (<1 hr) | `-Password` | Custom ⚠️ |
| Production testing | `-ReturnPasswords` | Random ✅ |
| Quick internal demo | `-Password` | Custom ⚠️ |

## One-Liners

```powershell
# Training with shared group and provisioning:
$u=New-LabUser -UserCount 50 -UserPrefix "train" -ReturnPasswords; $u|Export-Csv "c.csv"; New-LabEnvironment -UserCount 50 -UserPrefix "train" -CreateSharedGroup -CreateProvisioningPolicies -AssignPolicies

# Quick demo users:
New-LabUser -UserCount 10 -UserPrefix "demo" -Password "DemoPass123!" -AddToLicenseGroup

# Capture and display:
New-LabUser -UserCount 5 -ReturnPasswords | Format-Table

# Export with timestamp:
New-LabUser -UserCount 100 -ReturnPasswords | Export-Csv "Creds_$(Get-Date -F 'yyyyMMdd_HHmm').csv"
```

## Get Help

```powershell
# Detailed help
Get-Help New-LabUser -Detailed

# Examples only
Get-Help New-LabUser -Examples

# Full help with technical details
Get-Help New-LabUser -Full
```

## Related Functions

- `New-LabEnvironment` - Uses New-LabUser internally
- `Get-LabUser` - Retrieve created users  
- `Remove-LabUser` - Clean up users
- `New-LabGroup` - Create groups
- `Add-LabUserToGroup` - Add users to groups

## Files & Documentation

- 📘 Complete Guide: `RANDOM_PASSWORD_FEATURE.md`
- 📝 Implementation Summary: `RANDOM_PASSWORD_IMPLEMENTATION_SUMMARY.md`
- 💻 Examples: `Examples/RandomPasswordExample.ps1`
- ✅ Test: `Examples/TestRandomPasswordFeature.ps1`
