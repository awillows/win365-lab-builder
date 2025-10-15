# Windows 365 Lab Builder Module

## Overview

The Windows 365 Lab Builder is a comprehensive PowerShell module designed for creating and managing Windows 365 lab environments. It provides enterprise-grade functions for user management, group operations, Cloud PC provisioning, and complete lab orchestration with robust error handling and security best practices.

## Features

### Core Capabilities
- **👥 User Management**: Bulk creation with random passwords and standardized naming
- **🔒 Security Groups**: Automated group creation and membership management
- **🖥️ Cloud PC Provisioning**: Windows 365 policy creation and assignment
- **⚙️ User Settings**: Cloud PC user experience and administrative controls
- **🌍 Regional Support**: Multi-region Cloud PC deployment capabilities
- **💼 License Management**: Group-based license assignment automation
- **📊 Monitoring**: Cloud PC lifecycle and status tracking
- **🏗️ Orchestration**: Complete environment setup and teardown workflows

### Enterprise Features
- **🔐 Authentication**: Simplified Microsoft Graph connectivity with token management
- **✅ Validation**: Comprehensive input validation and parameter checking  
- **🛡️ Error Handling**: Robust error handling with detailed logging
- **🔄 Retry Logic**: Automatic retry for transient failures
- **📋 Progress Tracking**: Visual progress indicators for long-running operations
- **🧹 Cleanup Safety**: Confirmation prompts and WhatIf support for destructive operations

## Prerequisites

- PowerShell 5.1 or later
- Microsoft Graph PowerShell modules:
  - Microsoft.Graph.Authentication
  - Microsoft.Graph.Users
  - Microsoft.Graph.Groups
  - Microsoft.Graph.DeviceManagement

## Installation

1. Install required Microsoft Graph modules:
```powershell
Install-Module Microsoft.Graph.Authentication -Force
Install-Module Microsoft.Graph.Users -Force
Install-Module Microsoft.Graph.Groups -Force
Install-Module Microsoft.Graph.DeviceManagement -Force
```

2. Import the Windows 365 Lab Builder Module:
```powershell
Import-Module .\W365LabBuilder\W365LabBuilder.psd1
```

## Quick Start

### Basic Lab Environment Setup

```powershell
# Connect to Microsoft Graph
Connect-LabGraph

# Create a complete lab environment with 10 users
# Uses Microsoft-hosted network by default (no connection required)
$result = New-LabEnvironment -UserCount 10 `
    -CreateIndividualGroups -CreateProvisioningPolicies -AssignPolicies

# Optional: Use Azure network connection if you have one configured
# $connection = Get-MgDeviceManagementVirtualEndpointOnPremisesConnection | Select-Object -First 1
# $result = New-LabEnvironment -UserCount 10 `
#     -CreateIndividualGroups -CreateProvisioningPolicies -AssignPolicies `
#     -OnPremisesConnectionId $connection.Id

# Check the results
Write-Host "Created $($result.Users.Count) users, $($result.Groups.Count) groups, $($result.Policies.Count) policies"
```

### Individual Operations

```powershell
# Create users
$users = New-LabUser -UserCount 5 -UserPrefix "TestUser" -AddToLicenseGroup

# Create groups
$group = New-LabGroup -GroupName "Test Lab Group"

# Add users to group
foreach ($user in $users) {
    Add-LabUserToGroup -UserPrincipalName $user.UserPrincipalName -GroupName "Test Lab Group"
}

# Create provisioning policy (uses Microsoft-hosted network by default)
$policy = New-LabCloudPCPolicy -PolicyName "Test Policy" -EnableSingleSignOn

# Optional: Use Azure network connection if you have one
# $connection = Get-MgDeviceManagementVirtualEndpointOnPremisesConnection | Select-Object -First 1
# $policy = New-LabCloudPCPolicy -PolicyName "Test Policy" `
#     -OnPremisesConnectionId $connection.Id `
#     -EnableSingleSignOn

# Assign policy to group
Set-LabPolicyAssignment -PolicyId $policy.Id -GroupName "Test Lab Group"
```

### Cleanup

```powershell
# Remove complete lab environment
Remove-LabEnvironment -UserPrefix "lu" -RemovePolicies -RemoveGroups -RemoveUsers -Force

# Disconnect from Graph
Disconnect-LabGraph
```

## Function Reference

### Authentication Functions

| Function | Description |
|----------|-------------|
| `Connect-LabGraph` | Connects to Microsoft Graph with lab management scopes |
| `Disconnect-LabGraph` | Disconnects from Microsoft Graph |
| `Test-LabGraphConnection` | Tests current Graph connection |

### User Management Functions

| Function | Description |
|----------|-------------|
| `New-LabUser` | Creates lab users with standardized naming |
| `Remove-LabUser` | Removes users by prefix or UPN |
| `Get-LabUser` | Retrieves users with optional filtering |

### Group Management Functions

| Function | Description |
|----------|-------------|
| `New-LabGroup` | Creates security groups for lab use |
| `Remove-LabGroup` | Removes groups by name pattern |
| `Get-LabGroup` | Retrieves groups with optional filtering |
| `Add-LabUserToGroup` | Adds users to groups |
| `Set-LabGroupLicense` | Assigns licenses to groups (group-based licensing) |
| `Remove-LabGroupLicense` | Removes licenses from groups |
| `Get-LabGroupLicense` | Retrieves license assignments for groups |
| `Get-LabAvailableLicense` | Lists all available licenses in the tenant |

### Cloud PC Functions

| Function | Description |
|----------|-------------|
| `New-LabCloudPCPolicy` | Creates Windows 365 provisioning policies |
| `Remove-LabCloudPCPolicy` | Removes provisioning policies |
| `Get-LabCloudPCPolicy` | Retrieves provisioning policies |
| `Set-LabPolicyAssignment` | Assigns policies to groups |
| `Get-LabCloudPC` | Retrieves Cloud PC information |
| `Stop-LabCloudPCGracePeriod` | Ends grace period for Cloud PCs |

### Cloud PC User Settings Functions

| Function | Description |
|----------|-------------|
| `New-LabCloudPCUserSettings` | Creates Windows 365 user settings policies |
| `Remove-LabCloudPCUserSettings` | Removes user settings policies |
| `Get-LabCloudPCUserSettings` | Retrieves user settings policies |
| `Set-LabUserSettingsAssignment` | Assigns user settings to groups |
| `Remove-LabUserSettingsAssignment` | Removes user settings assignments |

### Orchestration Functions

| Function | Description |
|----------|-------------|
| `New-LabEnvironment` | Creates complete lab environments |
| `Remove-LabEnvironment` | Removes complete lab environments |

## Configuration

The module uses default configuration values that can be customized:

```powershell
# Default values (internal to module)
$LabDefaults = @{
    UserPrefix = "lu"
    GroupPrefix = "Lab Group"
    LicenseGroupName = "LabLicenseGroup"
    RoleGroupName = "LabRoleGroup"
    DefaultPassword = "Lab2024!!"
    DefaultUsageLocation = "US"
    DefaultRegion = "eastus"
    DefaultTimeZone = "Pacific Standard Time"
    DefaultLanguage = "en-US"
    DefaultImageId = "microsoftwindowsdesktop_windows-ent-cpc_win11-24H2-ent-cpc-m365"
    MaxUsers = 1000
}
```

## Error Handling

All functions include comprehensive error handling:

- Parameter validation with meaningful error messages
- Microsoft Graph connection verification
- Duplicate resource checking
- Graceful failure handling with detailed error information
- Support for `-WhatIf` and `-Confirm` parameters where appropriate

## Examples

### Example 1: Create Users for Training Lab

```powershell
Connect-LabGraph -TenantId "your-tenant-id"

# Create 20 training users with individual groups and a single shared provisioning policy
# Uses Microsoft-hosted network by default (simplest option)
$result = New-LabEnvironment -UserCount 20 -UserPrefix "train" `
    -CreateIndividualGroups -CreateProvisioningPolicies -AssignPolicies

# Optional: Use Azure network connection if needed
# $connection = Get-MgDeviceManagementVirtualEndpointOnPremisesConnection | Select-Object -First 1
# $result = New-LabEnvironment -UserCount 20 -UserPrefix "train" `
#     -CreateIndividualGroups -CreateProvisioningPolicies -AssignPolicies `
#     -OnPremisesConnectionId $connection.Id

Write-Host "Training lab created successfully!"
Write-Host "Users: $($result.Users.Count)"
Write-Host "Groups: $($result.Groups.Count)" 
Write-Host "Policies: $($result.Policies.Count)"  # Will be 1 (shared policy)
```

### Example 2: Cleanup Specific Lab

```powershell
# Remove only policies and groups, keep users
Remove-LabEnvironment -UserPrefix "train" -RemovePolicies -RemoveGroups

# Later remove users if needed
Remove-LabUser -UserPrefix "train" -Force
```

### Example 3: License Management

```powershell
# First, discover available licenses in your tenant
$licenses = Get-LabAvailableLicense
$licenses | Format-Table SkuPartNumber, ProductName, AvailableUnits, ConsumedUnits

# Find licenses with available units
$licenses | Where-Object AvailableUnits -gt 0 | Format-Table SkuPartNumber, ProductName, AvailableUnits

# Get details for a specific license
Get-LabAvailableLicense -SkuPartNumber "ENTERPRISEPACK" | Format-List

# Assign licenses to a group (all members will receive the license)
Set-LabGroupLicense -GroupName "LabLicenseGroup" -SkuPartNumber "ENTERPRISEPACK"

# Assign multiple licenses
Set-LabGroupLicense -GroupName "LabLicenseGroup" -SkuPartNumber "ENTERPRISEPACK","EMSPREMIUM"

# Check assigned licenses
$licenses = Get-LabGroupLicense -GroupName "LabLicenseGroup"
$licenses | Format-Table GroupName, SkuPartNumber, ProductName, ConsumedUnits

# Remove specific license from group
Remove-LabGroupLicense -GroupName "LabLicenseGroup" -SkuPartNumber "EMSPREMIUM"

# Remove all licenses from group
Remove-LabGroupLicense -GroupName "LabLicenseGroup" -RemoveAll
```

### Example 4: Windows 365 Provisioning Policies

```powershell
# Option 1: Create policy with Microsoft-hosted network (default - simplest)
$policy = New-LabCloudPCPolicy -PolicyName "Lab Policy" -EnableSingleSignOn

# Option 2: Create policy with Azure network connection (optional)
$connections = Get-MgDeviceManagementVirtualEndpointOnPremisesConnection
if ($connections) {
    $policy = New-LabCloudPCPolicy -PolicyName "Lab Policy Azure Network" `
        -OnPremisesConnectionId $connections[0].Id `
        -EnableSingleSignOn
}

# Create policy with custom image
$policy = New-LabCloudPCPolicy -PolicyName "Custom Image Policy" `
    -ImageId "microsoftwindowsdesktop_windows-ent-cpc_win11-23h2-ent-cpc-m365" `
    -ImageDisplayName "Windows 11 23H2 Enterprise" `
    -Locale "en-US"

# See Examples/ProvisioningPolicyExamples.ps1 for more detailed examples
```

### Example 5: Windows 365 User Settings Management

```powershell
# Create user settings policy with local admin enabled
$userSettings = New-LabCloudPCUserSettings -PolicyName "Lab Admin Settings" `
    -EnableLocalAdmin $true `
    -EnableSelfServiceRestore $true `
    -RestorePointFrequencyInHours 6

# Assign to groups
Set-LabUserSettingsAssignment -PolicyName "Lab Admin Settings" -GroupName "LabLicenseGroup"

# Check all user settings policies
Get-LabCloudPCUserSettings -All | Format-Table DisplayName, LocalAdminEnabled, SelfServiceEnabled, RestorePointFrequencyInHours

# Remove assignments when done
Remove-LabUserSettingsAssignment -PolicyName "Lab Admin Settings" -RemoveAll
```

### Example 6: Manage Cloud PC Grace Periods

```powershell
# Check Cloud PCs in grace period
$gracePeriodPCs = Get-LabCloudPC -Status "InGracePeriod"
Write-Host "Found $($gracePeriodPCs.Count) Cloud PCs in grace period"

# End grace period for all
Stop-LabCloudPCGracePeriod -All -Force
```

## Best Practices

1. **Always connect to Graph first**: Use `Connect-LabGraph` before any operations
2. **Use -WhatIf for testing**: Test operations before executing them
3. **Handle errors gracefully**: Wrap operations in try-catch blocks for production use
4. **Clean up resources**: Use `Remove-LabEnvironment` to clean up when done
5. **Validate parameters**: The module validates inputs, but verify your requirements
6. **Use appropriate scopes**: Ensure your Graph connection has sufficient permissions

## Troubleshooting

### Common Issues

1. **"Microsoft Graph connection required"**
   - Solution: Run `Connect-LabGraph` first

2. **"Insufficient privileges"** 
   - Solution: Ensure your account has required permissions and scopes

3. **"User/Group already exists"**
   - This is expected behavior; the module will skip existing resources

4. **Policy assignment failures**
   - Ensure groups exist before assigning policies

### Getting Help

Use PowerShell's built-in help system:

```powershell
Get-Help New-LabUser -Full
Get-Help Connect-LabGraph -Examples
```

## License

Copyright (c) Microsoft Corporation. All rights reserved.