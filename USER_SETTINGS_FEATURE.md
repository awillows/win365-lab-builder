# Windows 365 User Settings Management Feature

## Overview

The Windows 365 Lab Builder includes comprehensive Windows 365 user settings management functionality. User settings policies control the end-user experience on Cloud PCs, including local administrator access, self-service restore capabilities, and automatic restore point frequency.

## Why User Settings Matter

Windows 365 user settings policies are essential for:
- **Security Control**: Manage who has local administrator rights
- **User Empowerment**: Enable self-service restore without IT intervention
- **Data Protection**: Configure automatic restore point frequency
- **Compliance**: Meet organizational security policies
- **User Experience**: Balance control with user autonomy

## New Functions

### 1. New-LabCloudPCUserSettings

**Purpose:** Creates Windows 365 user settings policies

**Key Features:**
- Configure local administrator access (enabled/disabled)
- Enable/disable self-service restore capabilities
- Set automatic restore point frequency (4-24 hours)
- Associate with description and metadata
- Duplicate detection

**Parameters:**
- `PolicyName` (Mandatory): Name of the user settings policy
- `Description`: Policy description (default: "User settings policy for lab environment")
- `EnableLocalAdmin` (Boolean): Grant local admin rights (default: $false)
- `EnableSelfServiceRestore` (Boolean): Allow user-initiated restore (default: $true)
- `RestorePointFrequencyInHours` (4-24): Restore point interval (default: 12)

**Examples:**
```powershell
# Basic policy with defaults
New-LabCloudPCUserSettings -PolicyName "Standard Users"

# Admin-enabled policy
New-LabCloudPCUserSettings -PolicyName "Power Users" `
    -EnableLocalAdmin $true `
    -RestorePointFrequencyInHours 6

# Restricted policy
New-LabCloudPCUserSettings -PolicyName "Secure Environment" `
    -EnableLocalAdmin $false `
    -EnableSelfServiceRestore $false `
    -RestorePointFrequencyInHours 24
```

**Permissions Required:**
- DeviceManagementConfiguration.ReadWrite.All

---

### 2. Remove-LabCloudPCUserSettings

**Purpose:** Removes Windows 365 user settings policies

**Key Features:**
- Remove by name or ID
- Pattern matching with wildcards
- Automatic assignment cleanup
- Confirmation prompts (can be bypassed with -Force)
- Batch removal support

**Parameters:**
- `PolicyName`: Name or pattern of policy to remove
- `PolicyId`: Direct policy ID
- `Force`: Skip confirmation prompts

**Examples:**
```powershell
# Remove specific policy
Remove-LabCloudPCUserSettings -PolicyName "Test Policy"

# Remove multiple policies with pattern
Remove-LabCloudPCUserSettings -PolicyName "Lab*" -Force

# Remove by ID
Remove-LabCloudPCUserSettings -PolicyId "policy-guid" -Force
```

**Safety Features:**
- High ConfirmImpact (requires confirmation)
- Clears assignments before deletion
- Reports success/failure counts
- Graceful handling of missing policies

---

### 3. Get-LabCloudPCUserSettings

**Purpose:** Retrieves Windows 365 user settings policies

**Key Features:**
- Query all policies or filter by name/ID
- Pattern matching support
- Detailed configuration output
- No Graph connection required after initial authentication

**Parameters:**
- `PolicyName`: Name or pattern to filter
- `PolicyId`: Specific policy ID
- `All`: Returns all policies (default)

**Examples:**
```powershell
# Get all policies
Get-LabCloudPCUserSettings -All

# Find specific policy
Get-LabCloudPCUserSettings -PolicyName "Standard Users"

# Pattern matching
Get-LabCloudPCUserSettings -PolicyName "Lab*"

# Format for display
Get-LabCloudPCUserSettings -All | Format-Table DisplayName, LocalAdminEnabled, SelfServiceEnabled, RestorePointFrequencyInHours
```

**Output Structure:**
```powershell
DisplayName              : Standard Users
Description              : User settings policy for lab environment
Id                       : policy-guid
LocalAdminEnabled        : False
SelfServiceEnabled       : True
RestorePointFrequencyInHours : 12
CreatedDateTime          : 2025-10-13T...
LastModifiedDateTime     : 2025-10-13T...
```

---

### 4. Set-LabUserSettingsAssignment

**Purpose:** Assigns user settings policies to groups

**Key Features:**
- Assign to single or multiple groups
- Support for both group names and IDs
- Automatic policy and group lookup
- WhatIf support for testing
- Replaces existing assignments

**Parameters:**
- `PolicyName` / `PolicyId`: Target policy (one required)
- `GroupName` / `GroupId`: Target group(s) (one required, supports arrays)

**Examples:**
```powershell
# Assign to single group by name
Set-LabUserSettingsAssignment -PolicyName "Standard Users" -GroupName "All Users"

# Assign to multiple groups
Set-LabUserSettingsAssignment -PolicyId "policy-guid" -GroupId "group1-guid","group2-guid"

# Test assignment with WhatIf
Set-LabUserSettingsAssignment -PolicyName "Power Users" -GroupName "Developers" -WhatIf
```

**Assignment Behavior:**
- Assignments apply to all group members
- New members automatically receive settings
- Settings apply to their next Cloud PC session
- Can take 15-30 minutes to propagate

---

### 5. Remove-LabUserSettingsAssignment

**Purpose:** Removes group assignments from user settings policies

**Key Features:**
- Remove all assignments from a policy
- High safety with confirmation prompts
- Clean removal without orphaned assignments

**Parameters:**
- `PolicyName` / `PolicyId`: Target policy (one required)
- `RemoveAll`: Must be specified (safety measure)

**Examples:**
```powershell
# Remove all assignments
Remove-LabUserSettingsAssignment -PolicyName "Standard Users" -RemoveAll

# Remove with confirmation bypass
Remove-LabUserSettingsAssignment -PolicyId "policy-guid" -RemoveAll -Confirm:$false
```

**Note:** This does NOT delete the policy, only removes its group assignments.

---

## User Settings Configuration Guide

### Local Administrator Access

**When to Enable:**
- Developers needing software installation
- Power users requiring system configuration
- Training/lab environments
- Troubleshooting scenarios

**When to Disable:**
- Standard business users
- High-security environments
- Compliance-regulated industries
- Shared Cloud PCs

**Security Considerations:**
- Local admin = full control over Cloud PC
- Increased risk of malware installation
- Can bypass some security policies
- Consider Just-In-Time (JIT) access instead

---

### Self-Service Restore

**Benefits:**
- Users fix issues without IT tickets
- Reduces help desk burden
- Faster problem resolution
- Improved user satisfaction

**When to Enable:**
- Standard user scenarios
- Training environments
- Users with varying skill levels

**When to Disable:**
- Highly controlled environments
- Compliance requirements
- When data consistency is critical
- Shared devices

**How It Works:**
- User initiates restore from Cloud PC settings
- System restores to previous restore point
- User data may be lost since restore point
- IT not involved in process

---

### Restore Point Frequency

**Options:** 4, 6, 8, 12, 16, 24 hours

**Considerations:**

| Frequency | Use Case | Pros | Cons |
|-----------|----------|------|------|
| 4 hours | Development, Testing | Minimal data loss | Higher storage costs |
| 6 hours | Power users | Good balance | Moderate storage |
| 12 hours | Standard users | Cost-effective | Some data loss risk |
| 24 hours | Read-only, Kiosks | Lowest cost | Significant data loss risk |

**Best Practices:**
- More frequent = better protection but higher cost
- Consider user's work pattern
- Balance with backup strategy
- Review storage consumption regularly

---

## Complete Lab Workflow with User Settings

```powershell
# 1. Connect
Connect-LabGraph

# 2. Create users
$users = New-LabUser -UserCount 20 -UserPrefix "labuser"

# 3. Create groups (different roles)
$devGroup = New-LabGroup -GroupName "Lab Developers"
$userGroup = New-LabGroup -GroupName "Lab Users"

# 4. Assign users to groups (first 5 to dev, rest to users)
for ($i = 0; $i -lt 5; $i++) {
    Add-LabUserToGroup -UserPrincipalName $users[$i].UserPrincipalName -GroupId $devGroup.Id
}
for ($i = 5; $i -lt $users.Count; $i++) {
    Add-LabUserToGroup -UserPrincipalName $users[$i].UserPrincipalName -GroupId $userGroup.Id
}

# 5. Assign licenses
Set-LabGroupLicense -GroupId $devGroup.Id -SkuPartNumber "CPC_E_2"
Set-LabGroupLicense -GroupId $userGroup.Id -SkuPartNumber "CPC_E_1"

# 6. Create provisioning policies
$devPolicy = New-LabCloudPCPolicy -PolicyName "Dev Provisioning" -RegionName "westus"
$userPolicy = New-LabCloudPCPolicy -PolicyName "User Provisioning" -RegionName "eastus"

# 7. Create user settings (different for each role)
$devSettings = New-LabCloudPCUserSettings `
    -PolicyName "Developer Settings" `
    -EnableLocalAdmin $true `
    -EnableSelfServiceRestore $true `
    -RestorePointFrequencyInHours 4

$userSettings = New-LabCloudPCUserSettings `
    -PolicyName "Standard User Settings" `
    -EnableLocalAdmin $false `
    -EnableSelfServiceRestore $true `
    -RestorePointFrequencyInHours 12

# 8. Assign provisioning policies
Set-LabPolicyAssignment -PolicyId $devPolicy.Id -GroupId $devGroup.Id
Set-LabPolicyAssignment -PolicyId $userPolicy.Id -GroupId $userGroup.Id

# 9. Assign user settings
Set-LabUserSettingsAssignment -PolicyId $devSettings.Id -GroupId $devGroup.Id
Set-LabUserSettingsAssignment -PolicyId $userSettings.Id -GroupId $userGroup.Id

Write-Host "Complete lab setup with role-based user settings finished!"
```

---

## Integration with Existing Features

### Works With Provisioning Policies

User settings complement provisioning policies:
- **Provisioning Policy**: WHAT Cloud PC to create (size, image, network)
- **User Settings**: HOW users interact with their Cloud PC

Both are required for complete Windows 365 deployment.

### Works With License Management

Assignment flow:
1. Assign Windows 365 license to group
2. Assign provisioning policy to group
3. Assign user settings to group
4. Users in group get Cloud PCs with correct configuration

### Works With Orchestration

The `New-LabEnvironment` function can be extended to include user settings:
```powershell
# Future enhancement example
New-LabEnvironment -UserCount 10 `
    -CreateProvisioningPolicies `
    -CreateUserSettings `
    -UserSettingsProfile "Developer"
```

---

## Common Use Cases

### Use Case 1: Multi-Tier Lab Environment

**Scenario:** Training lab with instructors and students

```powershell
# Instructor settings - full control
$instructorSettings = New-LabCloudPCUserSettings `
    -PolicyName "Instructor Settings" `
    -EnableLocalAdmin $true `
    -EnableSelfServiceRestore $true `
    -RestorePointFrequencyInHours 6

# Student settings - restricted
$studentSettings = New-LabCloudPCUserSettings `
    -PolicyName "Student Settings" `
    -EnableLocalAdmin $false `
    -EnableSelfServiceRestore $true `
    -RestorePointFrequencyInHours 24

Set-LabUserSettingsAssignment -PolicyId $instructorSettings.Id -GroupName "Instructors"
Set-LabUserSettingsAssignment -PolicyId $studentSettings.Id -GroupName "Students"
```

### Use Case 2: Development vs Production

**Scenario:** Separate settings for different environments

```powershell
# Development - permissive
$devSettings = New-LabCloudPCUserSettings `
    -PolicyName "Dev Environment" `
    -EnableLocalAdmin $true `
    -RestorePointFrequencyInHours 4

# Production - locked down
$prodSettings = New-LabCloudPCUserSettings `
    -PolicyName "Prod Environment" `
    -EnableLocalAdmin $false `
    -EnableSelfServiceRestore $false `
    -RestorePointFrequencyInHours 24
```

### Use Case 3: Temporary Admin Access

**Scenario:** Grant admin temporarily for software installation

```powershell
# Create temporary admin policy
$tempAdmin = New-LabCloudPCUserSettings `
    -PolicyName "Temp Admin Access" `
    -EnableLocalAdmin $true `
    -RestorePointFrequencyInHours 4

# Assign to user's group
Set-LabUserSettingsAssignment -PolicyName "Temp Admin Access" -GroupName "User123-TempAdmin"

# After work done, revert
Remove-LabUserSettingsAssignment -PolicyName "Temp Admin Access" -RemoveAll
Set-LabUserSettingsAssignment -PolicyName "Standard Settings" -GroupName "User123-Standard"
```

---

## Troubleshooting

### Issue: Settings Not Applying

**Symptoms:** User doesn't have expected permissions

**Solutions:**
1. Verify user is in assigned group:
   ```powershell
   Get-MgGroupMember -GroupId "group-guid"
   ```
2. Check policy assignment:
   ```powershell
   Get-LabCloudPCUserSettings -PolicyName "YourPolicy"
   ```
3. Wait 15-30 minutes for propagation
4. User may need to sign out and back in
5. Check Cloud PC provisioning status

### Issue: Cannot Create Policy

**Symptoms:** Error when creating user settings

**Solutions:**
1. Verify permissions:
   ```powershell
   Test-LabGraphConnection
   ```
2. Check if policy name already exists:
   ```powershell
   Get-LabCloudPCUserSettings -All
   ```
3. Ensure connected to correct tenant
4. Verify Windows 365 licenses available

### Issue: Restore Points Not Created

**Symptoms:** No restore points at expected frequency

**Solutions:**
1. Verify user settings applied to group
2. Check Cloud PC is provisioned (not in grace period)
3. Restore points only created when PC is in use
4. Check Azure AD logs for errors
5. Verify sufficient storage allocation

---

## Best Practices

### 1. Principle of Least Privilege
- Default to NO local admin
- Only grant when necessary
- Use group-based assignment for control
- Review admin access quarterly

### 2. Testing First
- Create test policies before production
- Use `-WhatIf` parameter
- Test with small user group first
- Validate settings applied correctly

### 3. Documentation
- Document why each policy exists
- Track which groups have which settings
- Document exception approvals
- Keep change log

### 4. Regular Review
- Audit local admin assignments monthly
- Review restore frequency vs costs
- Check for unused policies
- Validate group memberships

### 5. Naming Conventions
- Use descriptive policy names
- Include purpose in description
- Consider prefix/suffix for organization
- Example: "LAB-PowerUsers-AdminEnabled"

---

## Cost Considerations

### Restore Point Storage

More frequent restore points = higher storage costs

**Estimation:**
- Average Cloud PC: 10-50 GB of changes per day
- 4-hour frequency: ~6 restore points per day
- 24-hour frequency: ~1 restore point per day
- Storage costs vary by region

**Cost Optimization:**
```powershell
# Use frequency based on role
$executives = 24  # Minimal changes
$developers = 6   # Frequent changes
$dataEntry = 12   # Moderate changes
```

### Administrative Overhead

**Self-Service Restore = Cost Savings:**
- Fewer help desk tickets
- Faster user resolution
- Less IT intervention required
- Higher user satisfaction

**Local Admin = Risk Costs:**
- Potential security incidents
- Compliance violations
- Data loss scenarios
- Consider security tooling costs

---

## Security Recommendations

### For Local Admin Access

1. **Use Conditional Access**
   - Require MFA for admin-enabled PCs
   - Limit access by location
   - Monitor for unusual activity

2. **Implement Monitoring**
   - Log admin actions
   - Alert on suspicious software installations
   - Regular security scans

3. **Training Required**
   - Educate users on risks
   - Require security awareness training
   - Document acceptable use

### For Self-Service Restore

1. **User Training**
   - When to use restore
   - Data loss implications
   - Alternative support options

2. **Backup Strategy**
   - Restore points != backups
   - Use OneDrive Known Folder Move
   - Regular backup validation

3. **Monitoring**
   - Track restore usage
   - Investigate frequent restores
   - Identify problematic applications

---

## Example Script Reference

Comprehensive examples available in:
```
W365LabBuilder/Examples/UserSettingsManagement.ps1
```

This script includes 13 detailed examples:
1. Basic policy creation
2. Admin-enabled settings
3. Restricted settings
4. Listing all policies
5. Group assignments
6. Complete lab setup
7. Query specific policies
8. Pattern-based queries
9. Managing assignments
10. Configuration comparison
11. Best practices demonstration
12. Selective cleanup
13. Complete cleanup

---

## Command Reference Quick Guide

| Task | Command |
|------|---------|
| Create policy | `New-LabCloudPCUserSettings -PolicyName "Name"` |
| Enable local admin | `-EnableLocalAdmin $true` |
| Set restore frequency | `-RestorePointFrequencyInHours 6` |
| List all policies | `Get-LabCloudPCUserSettings -All` |
| Find by pattern | `Get-LabCloudPCUserSettings -PolicyName "Lab*"` |
| Assign to group | `Set-LabUserSettingsAssignment -PolicyName "Name" -GroupName "Group"` |
| Remove assignment | `Remove-LabUserSettingsAssignment -PolicyName "Name" -RemoveAll` |
| Delete policy | `Remove-LabCloudPCUserSettings -PolicyName "Name"` |

---

## Version Information

- **Version**: 1.2.0
- **Release Date**: October 13, 2025
- **Module Functions**: 29 (up from 24)
- **User Settings Functions**: 5 (new)

---

## Additional Resources

### Microsoft Documentation
- [Windows 365 User Settings](https://learn.microsoft.com/en-us/windows-365/)
- [Graph API: cloudPcUserSetting](https://learn.microsoft.com/en-us/graph/api/resources/cloudpcusersetting)
- [Group-based assignments](https://learn.microsoft.com/en-us/graph/api/resources/devicemanagement)

### Module Help
```powershell
Get-Help New-LabCloudPCUserSettings -Full
Get-Help Set-LabUserSettingsAssignment -Examples
Get-Help Remove-LabCloudPCUserSettings -Detailed
```

### Support
For issues or questions:
1. Review documentation in README.md
2. Check example scripts
3. Run Pester tests for validation
4. Review CHANGELOG.md for known issues

---

## Next Steps

1. **Review the example script**: `UserSettingsManagement.ps1`
2. **Test in non-production**: Use `-WhatIf` parameter
3. **Start small**: Begin with one or two policies
4. **Monitor impact**: Track usage and costs
5. **Iterate**: Adjust based on feedback

For more information, see the main README.md or module-specific documentation.
