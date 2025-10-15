# Cloud PC Policy Assignment Options

## Overview

The `New-LabEnvironment` function now supports **three different methods** for assigning Cloud PC provisioning policies to users. Each method has different use cases and benefits.

## Assignment Options

### Option 1: Individual Groups (`-CreateIndividualGroups`)

**Description:** Creates one security group per user and assigns the provisioning policy to each group individually.

**Use When:**
- You need maximum granularity and control
- Each user requires individual group-level management
- You want to easily target specific users for policy changes
- Lab environments with diverse user requirements

**Example:**
```powershell
New-LabEnvironment -UserCount 20 -UserPrefix "lu" `
    -CreateIndividualGroups `
    -CreateProvisioningPolicies `
    -AssignPolicies `
    -RegionName "eastus"
```

**Result:**
- 20 users created
- 20 groups created (one per user)
- 1 provisioning policy created
- Policy assigned to all 20 groups

**Group Names:** `Lab Group for labuser001`, `Lab Group for labuser002`, etc.

---

### Option 2: Shared Group (`-CreateSharedGroup`) ⭐ NEW

**Description:** Creates ONE security group containing all users and assigns the provisioning policy to that single group.

**Use When:**
- You want simplified group management
- All users share the same Cloud PC configuration
- Large-scale deployments (50+ users)
- Training environments or cohort-based labs
- You want to reduce Azure AD object count

**Example:**
```powershell
New-LabEnvironment -UserCount 200 -UserPrefix "lab" `
    -CreateSharedGroup `
    -CreateProvisioningPolicies `
    -AssignPolicies `
    -RegionName "westeurope"
```

**Result:**
- 200 users created
- 1 group created (containing all 200 users)
- 1 provisioning policy created
- Policy assigned to 1 shared group

**Group Name:** `Lab Shared Group - lab`

**Benefits:**
- Easier to manage at scale
- Reduces Azure AD object proliferation
- Simpler policy assignments
- Better for cohort-based training

---

### Option 3: Default License Group (no group flag)

**Description:** Uses the existing default license group for policy assignment. No new groups are created.

**Use When:**
- You already have group memberships established
- Users are already in the appropriate license group
- You want minimal changes to group structure
- Quick testing or simple scenarios

**Example:**
```powershell
New-LabEnvironment -UserCount 10 -UserPrefix "demo" `
    -CreateProvisioningPolicies `
    -AssignPolicies `
    -RegionName "eastus"
```

**Result:**
- 10 users created (added to existing license group)
- 0 new groups created
- 1 provisioning policy created
- Policy assigned to default license group

**Default Group Name:** `LabLicenseGroup` (pre-existing)

---

## Comparison Matrix

| Feature | Individual Groups | Shared Group | Default License Group |
|---------|------------------|--------------|---------------------|
| Groups Created | One per user | One for all users | None (uses existing) |
| Management Complexity | High | Low | Lowest |
| Best For | Granular control | Large cohorts | Existing structure |
| Scalability | 1:1 ratio | Excellent | Excellent |
| Example: 100 users | 100 groups | 1 group | 0 groups |
| Azure AD Objects | High | Minimal | None |
| Policy Flexibility | Individual targeting | Group-level | Existing group |

## Mutual Exclusivity

⚠️ **Important:** `-CreateIndividualGroups` and `-CreateSharedGroup` are **mutually exclusive**. You can only use one per lab environment creation.

**This will error:**
```powershell
# ❌ INVALID - Cannot use both flags
New-LabEnvironment -UserCount 50 `
    -CreateIndividualGroups `
    -CreateSharedGroup  # ERROR!
```

## Real-World Scenarios

### Scenario 1: Instructor-Led Training (50 students)
**Best Choice:** Shared Group
```powershell
New-LabEnvironment -UserCount 50 -UserPrefix "student" `
    -CreateSharedGroup -CreateProvisioningPolicies -AssignPolicies
```
**Why:** All students need identical Cloud PCs, easier for instructor to manage one group.

### Scenario 2: Developer Lab (10 individuals)
**Best Choice:** Individual Groups
```powershell
New-LabEnvironment -UserCount 10 -UserPrefix "dev" `
    -CreateIndividualGroups -CreateProvisioningPolicies -AssignPolicies
```
**Why:** May need to adjust individual developer environments, easier with separate groups.

### Scenario 3: Conference Demo (5 users)
**Best Choice:** Default License Group
```powershell
New-LabEnvironment -UserCount 5 -UserPrefix "demo" `
    -CreateProvisioningPolicies -AssignPolicies
```
**Why:** Quick setup, minimal overhead, users already licensed.

### Scenario 4: Large Scale Hydration (500 users)
**Best Choice:** Shared Group
```powershell
New-LabEnvironment -UserCount 500 -UserPrefix "lab" `
    -CreateSharedGroup -CreateProvisioningPolicies -AssignPolicies
```
**Why:** Creating 500 individual groups would be excessive; one shared group is much cleaner.

## Migration Between Options

You can migrate between assignment methods by:

1. **Remove existing environment:**
   ```powershell
   Remove-LabEnvironment -UserPrefix "mylab" -RemovePolicies -RemoveGroups -Force
   ```

2. **Recreate with different option:**
   ```powershell
   New-LabEnvironment -UserCount 50 -UserPrefix "mylab" `
       -CreateSharedGroup -CreateProvisioningPolicies -AssignPolicies
   ```

## Technical Notes

### Group Membership Limits
- Azure AD groups support thousands of members
- Shared groups can easily handle 200+ users
- Individual groups have no practical limit for single-user membership

### Policy Assignment Behavior
- One provisioning policy can be assigned to multiple groups
- All three methods result in the same user experience
- Policy configuration is identical across all options

### Performance Considerations
- **Individual Groups:** Slower at scale (many API calls)
- **Shared Group:** Faster (fewer API calls)
- **Default Group:** Fastest (group already exists)

## Best Practices

1. **Use Shared Group for:**
   - Training cohorts
   - Large-scale deployments
   - Temporary environments
   - Consistent user experiences

2. **Use Individual Groups for:**
   - Development/testing environments
   - When granular control is needed
   - Small user counts (<20)
   - Individual customization requirements

3. **Use Default License Group for:**
   - Quick tests
   - Existing group structures
   - Minimal infrastructure changes
   - Users already properly grouped

## Summary

The addition of `-CreateSharedGroup` provides a **middle ground** between individual granular control and using existing infrastructure. It's particularly valuable for large-scale lab deployments where creating hundreds of individual groups would be excessive, but you still want a dedicated group for the lab cohort.

Choose the option that best fits your:
- Scale (user count)
- Management preferences
- Infrastructure complexity tolerance
- Use case requirements
