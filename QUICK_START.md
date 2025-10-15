# Quick Start Guide - Windows 365 Lab Builder

Get up and running with Windows 365 lab environments in minutes! This guide walks you through the essential steps to create your first lab.

## 📋 Prerequisites Checklist

Before you begin, ensure you have:

- [ ] **PowerShell 5.1 or later** installed
- [ ] **Appropriate Azure AD permissions**:
  - User administrator or Global administrator role
  - License assignment permissions
- [ ] **Windows 365 licenses** available in your tenant
- [ ] **Azure subscription** for Cloud PC resources

## 🚀 5-Minute Setup

### Step 1: Install Required Modules

```powershell
# Install Microsoft Graph PowerShell modules
Install-Module Microsoft.Graph.Authentication -Force
Install-Module Microsoft.Graph.Users -Force
Install-Module Microsoft.Graph.Groups -Force
Install-Module Microsoft.Graph.DeviceManagement -Force
```

### Step 2: Import the Lab Builder Module

```powershell
# Navigate to your project directory
cd "C:\path\to\win365-lab-builder"

# Import the module
Import-Module .\W365LabBuilder\W365LabBuilder.psd1

# Verify installation
Get-Module W365LabBuilder
```

### Step 3: Connect to Microsoft Graph

```powershell
# Connect with device code authentication (recommended for first use)
Connect-LabGraph

# Or connect to specific tenant
Connect-LabGraph -TenantId "your-tenant-id"

# Verify connection
Test-LabGraphConnection
```

### Step 4: Create Your First Lab

```powershell
# Create a complete lab environment with 10 users
$myLab = New-LabEnvironment -UserCount 10 -CreateSharedGroup -CreateProvisioningPolicies -AssignPolicies

# View the results
Write-Host "✅ Lab created successfully!"
Write-Host "   Users: $($myLab.Users.Count)"
Write-Host "   Groups: $($myLab.Groups.Count)"
Write-Host "   Policies: $($myLab.Policies.Count)"
```

### Step 5: Export User Credentials

```powershell
# Export user credentials to CSV
$myLab.Users | Export-Csv "MyLabCredentials.csv" -NoTypeInformation

Write-Host "📄 Credentials saved to MyLabCredentials.csv"
Write-Host "⚠️  Store this file securely!"
```

## 🎯 Common Scenarios

### Scenario 1: Small Training Lab (5-20 users)
```powershell
# Perfect for workshops or small classes
$trainingLab = New-LabEnvironment `
    -UserCount 15 `
    -UserPrefix "training" `
    -CreateSharedGroup `
    -CreateProvisioningPolicies `
    -AssignPolicies `
    -RegionName "westus2"
```

### Scenario 2: Development Lab with Admin Access
```powershell
# Create developers with individual groups and admin settings
$devLab = New-LabEnvironment -UserCount 5 -UserPrefix "dev" -CreateIndividualGroups -CreateProvisioningPolicies -AssignPolicies

# Create user settings policy with local admin access
$adminSettings = New-LabCloudPCUserSettings -PolicyName "Dev Admin Settings" -EnableLocalAdmin $true
Set-LabUserSettingsAssignment -PolicyId $adminSettings.Id -GroupId $devLab.Groups[0].Id
```

### Scenario 3: Large Scale Lab (100+ users)
```powershell
# Efficient setup for large numbers using shared group
$largeLab = New-LabEnvironment `
    -UserCount 200 `
    -UserPrefix "lab" `
    -CreateSharedGroup `
    -CreateProvisioningPolicies `
    -AssignPolicies
    
Write-Host "Created $($largeLab.Users.Count) users in shared group: $($largeLab.Groups[0].DisplayName)"
```

## 📊 Monitor Your Lab

### Check Lab Status
```powershell
# View all lab users
Get-LabUser -UserPrefix "training"

# Check Cloud PC provisioning status
Get-LabCloudPC -All

# View group memberships
Get-LabGroup -GroupName "Training Lab*"

# Check policy assignments
Get-LabCloudPCPolicy -All
```

### License Management
```powershell
# Check available licenses
Get-LabAvailableLicense

# Assign specific license to group
Set-LabGroupLicense -GroupName "Training Lab Group" -SkuPartNumber "ENTERPRISEPACK"

# View group license assignments
Get-LabGroupLicense -GroupName "Training Lab Group"
```

## 🧹 Clean Up When Done

### Quick Cleanup
```powershell
# Remove everything for a specific user prefix
Remove-LabEnvironment -UserPrefix "training" -RemoveUsers -RemoveGroups -RemovePolicies -Force

# Disconnect from Graph
Disconnect-LabGraph
```

### Selective Cleanup
```powershell
# Remove only users (keep groups and policies)
Remove-LabEnvironment -UserPrefix "training" -RemoveUsers -Force

# Remove only policies
Remove-LabEnvironment -UserPrefix "training" -RemovePolicies -Force

# Remove individual resources
Remove-LabUser -UserPrincipalName "training01@domain.com" -Force
Remove-LabGroup -GroupName "Training Lab Group" -Force
```

## 🔧 Troubleshooting

### Connection Issues
```powershell
# Test your connection
Test-LabGraphConnection

# Reconnect if needed
Disconnect-LabGraph
Connect-LabGraph
```

### Permission Problems
- Ensure you have **User Administrator** or **Global Administrator** role
- Check that you can assign licenses in your tenant
- Verify Windows 365 Administrator permissions for Cloud PC operations

### Module Import Issues
```powershell
# Force reimport the module
Import-Module .\W365LabBuilder\W365LabBuilder.psd1 -Force

# Check if required Graph modules are installed
Get-Module Microsoft.Graph.* -ListAvailable
```

## 📚 Next Steps

### Learn More Advanced Features
1. **User Settings Policies**: Control local admin access and restore options
2. **Regional Deployments**: Deploy Cloud PCs to specific Azure regions
3. **License Management**: Automate group-based license assignment
4. **Monitoring & Lifecycle**: Track provisioning and manage Cloud PC lifecycle

### Explore Examples
- `Examples\BasicLabSetup.ps1` - Simple lab creation
- `Examples\AdvancedLabManagement.ps1` - Complex scenarios
- `Examples\CleanupLab.ps1` - Cleanup procedures

### Get Detailed Help
```powershell
# Function-specific help
Get-Help New-LabEnvironment -Full
Get-Help Connect-LabGraph -Examples

# List all available functions
Get-Command -Module W365LabBuilder
```

## ⚡ Quick Reference Commands

| Task | Command |
|------|---------|
| **Connect** | `Connect-LabGraph` |
| **Create 10-user lab** | `New-LabEnvironment -UserCount 10 -CreateSharedGroup -CreateProvisioningPolicies -AssignPolicies` |
| **Check users** | `Get-LabUser -UserPrefix "labuser"` |
| **Export credentials** | `$lab.Users \| Export-Csv "creds.csv"` |
| **Clean up lab** | `Remove-LabEnvironment -UserPrefix "labuser" -RemoveAll -Force` |
| **Disconnect** | `Disconnect-LabGraph` |

## 🆘 Need Help?

- **Documentation**: Check the main [README.md](../README.md) for complete reference
- **Examples**: Browse the [Examples](../Examples/) folder for detailed scenarios
- **PowerShell Help**: Use `Get-Help` for any function
- **Issues**: Create issues in the project repository

---

**🎉 You're ready to build Windows 365 labs!** Start with a small test lab and gradually explore the advanced features as you become more comfortable with the module.