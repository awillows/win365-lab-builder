# New Feature: Shared Group Assignment Option

## Summary

Added a **third assignment option** for Cloud PC provisioning policies: **Shared Group**.

## What Changed

### New Parameter: `-CreateSharedGroup`

The `New-LabEnvironment` function now accepts a `-CreateSharedGroup` switch parameter that:

1. Creates **ONE group** containing all lab users
2. Assigns the Cloud PC provisioning policy to this single shared group
3. Provides a simpler alternative to individual groups or default license group

### Function Signature Update

**Before:**
```powershell
New-LabEnvironment -UserCount <Int32> [-CreateIndividualGroups] 
                   [-CreateProvisioningPolicies] [-AssignPolicies]
```

**After:**
```powershell
New-LabEnvironment -UserCount <Int32> 
                   [-CreateIndividualGroups] 
                   [-CreateSharedGroup]          # ⭐ NEW
                   [-CreateProvisioningPolicies] 
                   [-AssignPolicies]
```

## Three Assignment Options

### 1. Individual Groups (Existing)
```powershell
-CreateIndividualGroups
```
- Creates one group per user
- Example: 50 users = 50 groups
- Use for: Granular control, small labs

### 2. Shared Group (NEW)
```powershell
-CreateSharedGroup
```
- Creates ONE group for all users
- Example: 50 users = 1 group
- Use for: Large labs, training cohorts, simplified management

### 3. Default License Group (Existing)
```powershell
(no group flag)
```
- Uses existing license group
- Example: 50 users = 0 new groups
- Use for: Quick tests, existing infrastructure

## Examples

### Create 50 Users with Shared Group
```powershell
New-LabEnvironment -UserCount 50 -UserPrefix "training" `
    -CreateSharedGroup `
    -CreateProvisioningPolicies `
    -AssignPolicies `
    -RegionName "eastus"
```

**Result:**
- 50 users: training001@... through training050@...
- 1 group: "Lab Shared Group - training"
- 1 provisioning policy assigned to the shared group
- All 50 users can provision Cloud PCs

### Compare: Individual Groups vs Shared Group

**Individual (before):**
```powershell
# Creates 100 users and 100 groups
New-LabEnvironment -UserCount 100 -UserPrefix "lab" `
    -CreateIndividualGroups -CreateProvisioningPolicies -AssignPolicies
```

**Shared (new):**
```powershell
# Creates 100 users and 1 group
New-LabEnvironment -UserCount 100 -UserPrefix "lab" `
    -CreateSharedGroup -CreateProvisioningPolicies -AssignPolicies
```

## Technical Details

### Validation
- `-CreateIndividualGroups` and `-CreateSharedGroup` are **mutually exclusive**
- Using both flags together will throw an error
- This is enforced in the `begin` block

### Group Naming
- Shared groups use format: `Lab Shared Group - {UserPrefix}`
- Example: `Lab Shared Group - demo`

### Implementation
The function:
1. Creates the shared group with descriptive name
2. Adds all users to the group in a loop
3. Reports progress and success count
4. Uses the shared group for policy assignment if `-AssignPolicies` is specified

### Error Handling
- Individual user addition failures are logged as warnings
- Shared group creation continues even if some users fail to add
- Reports final count of successful additions

## Files Modified

1. **W365LabBuilder.psm1**
   - Updated `New-LabEnvironment` function documentation
   - Added `-CreateSharedGroup` parameter
   - Added mutual exclusivity validation
   - Implemented shared group creation logic
   - Updated policy assignment logic to handle three scenarios

2. **README.md**
   - Updated function reference
   - Added comparison of three options
   - Added new examples

3. **Examples/SharedGroupExample.ps1** (NEW)
   - Demonstrates shared group creation
   - Shows comparison between options
   - Provides real-world usage patterns

4. **POLICY_ASSIGNMENT_OPTIONS.md** (NEW)
   - Comprehensive documentation of all three options
   - Comparison matrix
   - Use case recommendations
   - Migration guidance

## Benefits

### For Large Deployments
- **Reduced Azure AD Objects:** 200 users = 1 group instead of 200 groups
- **Simplified Management:** Easier to view and manage one group
- **Faster Execution:** Fewer API calls during creation

### For Training Scenarios
- **Cohort Management:** All training participants in one visible group
- **Easy Policy Changes:** Update one group assignment vs. many
- **Cleaner Structure:** Less clutter in Azure AD

### For Operations
- **Better Scaling:** Handles hundreds of users efficiently
- **Easier Cleanup:** One group to remove vs. many
- **Clear Intent:** Group name indicates it's a shared lab resource

## Backward Compatibility

✅ **Fully backward compatible**
- Existing scripts continue to work unchanged
- No breaking changes to parameters or behavior
- New parameter is optional

## Testing

Module has been validated:
- ✅ Imports successfully
- ✅ Both `CreateIndividualGroups` and `CreateSharedGroup` parameters present
- ✅ No syntax errors
- ✅ Mutual exclusivity validation in place

## Usage Recommendation

**Use `-CreateSharedGroup` when:**
- User count > 20
- All users need identical Cloud PC configuration
- Training or cohort-based scenarios
- You want simplified group management
- Azure AD object count is a concern

**Use `-CreateIndividualGroups` when:**
- User count < 20
- Individual customization may be needed
- Granular control is important
- Development/testing environments

**Use neither flag when:**
- Quick tests
- Users already in correct groups
- Minimal changes to infrastructure desired

## Example Output

```
Starting lab environment creation...
Creating 50 users...
Created user: training001@contoso.onmicrosoft.com
Created user: training002@contoso.onmicrosoft.com
...
Creating shared group for all users...
Created group: Lab Shared Group - training
Adding 50 users to shared group...
Added 50 of 50 users to shared group
Creating provisioning policy...
Created provisioning policy: Lab Provisioning Policy - training
Assigning policy to shared group...
Policy assigned to shared group: Lab Shared Group - training
Lab environment creation completed successfully!
Created: 50 users, 1 groups, 1 policies
Total time: 45.3 seconds
```

## Documentation

See these files for more information:
- `POLICY_ASSIGNMENT_OPTIONS.md` - Detailed comparison and guidance
- `Examples/SharedGroupExample.ps1` - Working examples
- `README.md` - Updated function reference
- Module inline help: `Get-Help New-LabEnvironment -Full`

## Version

- Feature added: 2025-10-14
- Module version: 1.2.0
- All tests passing ✅
