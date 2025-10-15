# Windows 365 Lab Builder: Random Password Feature

## Overview

The Windows 365 Lab Builder provides secure password management for lab environments through the `New-LabUser` function. By default, it generates **unique random passwords** for each user, providing enhanced security for Windows 365 lab environments.

## Password Options

### 🔐 Random Passwords (Default - Recommended)

By default, `New-LabUser` generates unique random passwords for each user, providing maximum security.

```powershell
# Each user gets a unique 16-character random password
$users = New-LabUser -UserCount 50 -UserPrefix "training" -ReturnPasswords

# Export credentials for distribution
$users | Export-Csv "TrainingCredentials.csv" -NoTypeInformation
```

**Benefits:**
- ✅ Unique password per user
- ✅ 16-character cryptographically random passwords  
- ✅ Meets Azure AD complexity requirements
- ✅ Best security for production training environments
- ✅ Prevents password sharing between users

**Password Characteristics:**
- Length: 16 characters
- Uppercase letters: 2+ (A-Z)
- Lowercase letters: 2+ (a-z) 
- Numbers: 2+ (2-9)
- Symbols: 2+ (!@#$%^&*)
- High entropy and unpredictable

### 📋 Custom Passwords

For demos and short-term labs, you can specify a custom password that all users will share.

```powershell
# All users get the same custom password
New-LabUser -UserCount 10 -UserPrefix "demo" -Password "DemoLab2025!"
```

**Use Cases:**
- Conference demonstrations (<1 hour)
- Quick internal testing
- Instructor-led workshops where password needs to be announced
- Temporary environments with minimal security requirements

**⚠️ Security Considerations:**
- Same password for all users
- Should only be used for short-term labs
- Not recommended for multi-day training events
- Consider credential rotation for extended use

## New Parameters

### `-Password` (String)

When specified, uses the same custom password for all users.

**Use when:**
- Quick demos or testing
- Short-lived lab environments (<1 hour)
- Conference booth demos
- You need a consistent, easy-to-communicate password

**Example:**
```powershell
New-LabUser -UserCount 10 -UserPrefix "demo" -Password "QuickDemo123!"
```

### `-ReturnPasswords` (Switch)

Returns user credentials (UPN + password) instead of just user objects.

**Use when:**
- You need to capture random passwords for distribution
- Creating credentials for training participants
- Exporting to CSV or other formats

**Example:**
```powershell
$credentials = New-LabUser -UserCount 50 -ReturnPasswords
$credentials | Export-Csv -Path "Credentials.csv" -NoTypeInformation
```

**Output includes:**
- `UserPrincipalName` - Full UPN (e.g., user001@contoso.com)
- `DisplayName` - Display name (e.g., "Lab User 001")
- `Password` - The generated or default password
- `Username` - Username portion (e.g., user001)

## Password Generation

### Random Password Characteristics

- **Length:** 16 characters
- **Complexity:** Includes uppercase, lowercase, numbers, and symbols
- **Character Sets:**
  - Uppercase: A-Z (excluding I, O for clarity)
  - Lowercase: a-z (excluding l for clarity)
  - Numbers: 2-9 (excluding 0, 1 for clarity)
  - Symbols: !@#$%^&*
- **Distribution:** Guaranteed minimum of 2 characters from each set
- **Randomization:** Uses PowerShell's `Get-Random` for shuffling

### Example Random Passwords

```
Qw45$#HnPx92@kTz
Kb$8Tr#6Yx@4MnP9
Dn92@Fz$3Qw#8JxK
```

## Usage Examples

### Example 1: Training Workshop (50 participants)

```powershell
# Connect to Graph
Connect-LabGraph

# Create users with random passwords and capture credentials
$workshopUsers = New-LabUser `
    -UserCount 50 `
    -UserPrefix "workshop" `
    -AddToLicenseGroup `
    -ReturnPasswords `
    -Verbose

# Export credentials for distribution to participants
$workshopUsers | Export-Csv -Path "C:\Secure\WorkshopCredentials.csv" -NoTypeInformation

# Display summary
Write-Host "Created $($workshopUsers.Count) users"
Write-Host "Credentials saved to WorkshopCredentials.csv"
$workshopUsers | Select-Object -First 5 | Format-Table
```

### Example 2: Quick Demo (Custom Password)

```powershell
# Create demo users with shared password
New-LabUser -UserCount 5 -UserPrefix "demo" -Password "QuickDemo123!"

Write-Host "✅ Demo users created"
Write-Host "🔑 Shared password: QuickDemo123!"
Write-Host "⏰ Recommended for sessions under 1 hour"
```

### Example 3: Complete Lab with Passwords

```powershell
# Create complete environment with credential export
$labUsers = New-LabUser -UserCount 25 -UserPrefix "lab" -ReturnPasswords

# Create the rest of the lab environment
$labEnv = New-LabEnvironment -UserCount 25 -UserPrefix "lab" -CreateSharedGroup -CreateProvisioningPolicies -AssignPolicies

# Export comprehensive credentials
$labUsers | Select-Object DisplayName, UserPrincipalName, Password | 
    Export-Csv "CompleteLabCredentials.csv" -NoTypeInformation
```

## Implementation Examples

### Secure Training Environment (Recommended)

```powershell
# Create users with unique random passwords
$trainingUsers = New-LabUser -UserCount 100 -UserPrefix "workshop" -ReturnPasswords

# Export with timestamp for organization
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$credFile = "Workshop_Credentials_$timestamp.csv"
$trainingUsers | Export-Csv $credFile -NoTypeInformation

Write-Host "✅ Created $($trainingUsers.Count) users with unique passwords"
Write-Host "📄 Credentials saved to: $credFile"
Write-Host "🔒 Store this file securely and distribute to participants"
```

### Quick Demo Environment

```powershell
# Create demo users with shared password
New-LabUser -UserCount 5 -UserPrefix "demo" -Password "QuickDemo123!"

Write-Host "✅ Demo users created"
Write-Host "🔑 Shared password: QuickDemo123!"
Write-Host "⏰ Recommended for sessions under 1 hour"
```

## Best Practices

### ✅ Do This

- **Always use random passwords** for production training environments
- **Use `-ReturnPasswords`** when participants need credentials
- **Export to secure location** and distribute through encrypted channels
- **Use descriptive prefixes** that identify the lab/event
- **Include timestamps** in credential files for tracking
- **Rotate passwords regularly** for extended training programs
- **Delete credential files** after distribution

### ❌ Don't Do This

- Don't use the same password for production training
- Don't store credentials in unsecured locations
- Don't share credential files via unencrypted email
- Don't use weak custom passwords
- Don't reuse passwords across different events
- Don't leave credential files on shared computers

## Security Recommendations

### For Production Training (Multi-day)

```powershell
# Use random passwords with secure distribution
$users = New-LabUser -UserCount 100 -UserPrefix "training" -ReturnPasswords

# Export to secure location
$secureFile = "\\secure-server\training\credentials_$(Get-Date -Format 'yyyyMMdd').csv"
$users | Export-Csv $secureFile -NoTypeInformation

# Optionally create individual PDFs or encrypted files per participant
```

### For Short Demos (<1 hour)

```powershell
# Custom password is acceptable for very short sessions
New-LabUser -UserCount 10 -UserPrefix "demo" -Password "Demo2025!!"
```

### For Development/Testing

```powershell
# Use custom password for internal testing
New-LabUser -UserCount 5 -UserPrefix "test" -Password "TestLab123!!" 
```

## Migration from Previous Versions

### Before (v1.1.0 and earlier)

```powershell
# Created users with hardcoded password "Lab2024!!"
$users = New-LabUser -UserCount 10 -UserPrefix "demo"

# Everyone knew the password was "Lab2024!!"
# Security risk for extended use
```

### After (v1.2.0+)

```powershell
# Now generates unique passwords by default
$users = New-LabUser -UserCount 10 -UserPrefix "demo" -ReturnPasswords

# Each user has a unique 16-character random password
# Much more secure for production use
```

## Advanced Scenarios

### Bulk Training Event

```powershell
# Create different user cohorts with different prefixes
$developers = New-LabUser -UserCount 20 -UserPrefix "dev" -ReturnPasswords
$admins = New-LabUser -UserCount 10 -UserPrefix "admin" -ReturnPasswords
$users = New-LabUser -UserCount 50 -UserPrefix "user" -ReturnPasswords

# Combine and export by role
$allUsers = @()
$allUsers += $developers | Select-Object @{Name="Role";Expression={"Developer"}}, *
$allUsers += $admins | Select-Object @{Name="Role";Expression={"Administrator"}}, *
$allUsers += $users | Select-Object @{Name="Role";Expression={"End User"}}, *

$allUsers | Export-Csv "TrainingEvent_AllCredentials.csv" -NoTypeInformation
```

### Credential Security

```powershell
# Generate passwords and immediately secure them
$credentials = New-LabUser -UserCount 50 -UserPrefix "secure" -ReturnPasswords

# Create encrypted credential packages
foreach ($cred in $credentials) {
    $secureString = ConvertTo-SecureString $cred.Password -AsPlainText -Force
    $encryptedFile = "credential_$($cred.Username).xml"
    $secureString | Export-Clixml $encryptedFile
}

Write-Host "Created $($credentials.Count) encrypted credential files"
```

## Troubleshooting

### Password Complexity Issues

If you encounter password complexity errors:

```powershell
# The module handles this automatically, but custom passwords must meet requirements
New-LabUser -UserCount 5 -Password "MyCustomPass123!@#"  # ✅ Good
New-LabUser -UserCount 5 -Password "simple"              # ❌ Will fail
```

### Missing Credentials

If passwords aren't returned:

```powershell
# Make sure to use -ReturnPasswords switch
$users = New-LabUser -UserCount 10 -ReturnPasswords  # ✅ Returns passwords
$users = New-LabUser -UserCount 10                   # ❌ No passwords returned
```

## Summary

**Security First:** When in doubt, use random passwords with `-ReturnPasswords` and secure credential distribution.

**Key Benefits of Random Passwords:**
- Unique per user (no sharing)
- Cryptographically secure
- Meets compliance requirements
- Reduces security risks

**Version History:**
- **v1.2.0** and later: Random passwords by default, `-ReturnPasswords` parameter
- **v1.1.0** and earlier: Used hardcoded default password "Lab2024!!"

For more examples, see the `Examples/RandomPasswordExample.ps1` script in the module.