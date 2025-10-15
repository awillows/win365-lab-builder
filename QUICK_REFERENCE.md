# Quick Reference: Cloud PC Policy Assignment Options

## Choose Your Assignment Method

```
┌─────────────────────────────────────────────────────────────────┐
│                    Assignment Decision Tree                      │
└─────────────────────────────────────────────────────────────────┘

How many users? 
  │
  ├─ < 20 users → Consider Individual Groups
  │   └─ New-LabEnvironment -UserCount 10 -CreateIndividualGroups
  │
  ├─ 20-200 users → Consider Shared Group ⭐
  │   └─ New-LabEnvironment -UserCount 50 -CreateSharedGroup
  │
  └─ > 200 users → Shared Group or Default License Group
      └─ New-LabEnvironment -UserCount 500 -CreateSharedGroup
```

## Quick Commands

### Option 1: Individual Groups
```powershell
New-LabEnvironment -UserCount 20 -UserPrefix "lab" `
    -CreateIndividualGroups `
    -CreateProvisioningPolicies `
    -AssignPolicies `
    -RegionName "eastus"
```
**Creates:** 20 users, 20 groups, 1 policy

---

### Option 2: Shared Group ⭐ NEW
```powershell
New-LabEnvironment -UserCount 100 -UserPrefix "training" `
    -CreateSharedGroup `
    -CreateProvisioningPolicies `
    -AssignPolicies `
    -RegionName "eastus"
```
**Creates:** 100 users, 1 group, 1 policy

---

### Option 3: Default License Group
```powershell
New-LabEnvironment -UserCount 10 -UserPrefix "demo" `
    -CreateProvisioningPolicies `
    -AssignPolicies `
    -RegionName "eastus"
```
**Creates:** 10 users, 0 groups (uses existing), 1 policy

---

## At a Glance

| Option | Flag | Groups Created | Best For |
|--------|------|----------------|----------|
| Individual | `-CreateIndividualGroups` | One per user | Small labs (<20) |
| Shared ⭐ | `-CreateSharedGroup` | One for all | Medium-large labs (20-500) |
| Default | (none) | Zero | Quick tests |

## Common Scenarios

### Training Class (50 students)
```powershell
New-LabEnvironment -UserCount 50 -UserPrefix "student" `
    -CreateSharedGroup -CreateProvisioningPolicies -AssignPolicies
```

### Development Team (10 developers)
```powershell
New-LabEnvironment -UserCount 10 -UserPrefix "dev" `
    -CreateIndividualGroups -CreateProvisioningPolicies -AssignPolicies
```

### Conference Demo (5 users)
```powershell
New-LabEnvironment -UserCount 5 -UserPrefix "demo" `
    -CreateProvisioningPolicies -AssignPolicies
```

### Large Hydration (200 users)
```powershell
New-LabEnvironment -UserCount 200 -UserPrefix "lab" `
    -CreateSharedGroup -CreateProvisioningPolicies -AssignPolicies
```

## Key Points

✅ **Shared Group is NEW** - Use for simplified management at scale
✅ **Mutually Exclusive** - Can't use both CreateIndividualGroups and CreateSharedGroup
✅ **Same Policy** - All options create ONE policy for all users
✅ **User Experience** - Identical regardless of assignment method

## Full Documentation

- `POLICY_ASSIGNMENT_OPTIONS.md` - Complete comparison
- `SHARED_GROUP_FEATURE.md` - Feature details
- `Examples/SharedGroupExample.ps1` - Working examples
