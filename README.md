# Windows 365 Lab Builder

A comprehensive PowerShell module for managing Windows 365 lab environments including users, groups, and Cloud PC provisioning policies.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Function Reference](#function-reference)
- [Examples](#examples)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

The **Windows 365 Lab Builder** is an enterprise-grade PowerShell module designed to streamline the creation and management of Windows 365 lab environments. Whether you're setting up training labs, demonstration environments, or test scenarios, this module provides all the tools you need to automate the entire process.

### Key Benefits

✅ **Complete Automation** - End-to-end lab environment provisioning  
✅ **Enterprise Security** - Random password generation and secure practices  
✅ **Flexible Configuration** - Customizable settings for different scenarios  
✅ **Comprehensive Management** - Users, groups, licenses, and Cloud PC policies  
✅ **Easy Cleanup** - Simple removal of entire lab environments  
✅ **Professional Standards** - PowerShell best practices and error handling  

## ✨ Features

### User Management
- **Bulk User Creation**: Create multiple lab users with standardized naming
- **Random Password Generation**: Secure, unique passwords for each user
- **License Assignment**: Automatic assignment to license groups
- **Custom Attributes**: Configurable user properties and settings

### Group Management
- **Security Groups**: Automated creation of lab groups
- **Role-Assignable Groups**: Create groups for Entra ID role assignments
- **Directory Role Assignment**: Assign administrative roles to groups
- **License Management**: Group-based license assignment
- **Membership Control**: Easy user-to-group assignments
- **Individual or Shared Groups**: Flexible group assignment strategies

### Cloud PC Provisioning
- **Provisioning Policies**: Create and manage Windows 365 policies
- **User Settings Policies**: Configure Cloud PC user experience
- **Policy Assignment**: Automated assignment to users and groups
- **Multiple Regions**: Support for various Azure regions

### Environment Orchestration
- **Complete Lab Setup**: One-command environment creation
- **Cleanup Operations**: Safe removal of lab resources
- **Status Monitoring**: Track Cloud PC and user status
- **Progress Reporting**: Visual feedback during operations

## 📋 Prerequisites

Before using the Windows 365 Lab Builder, ensure you have:

1. **PowerShell 5.1 or later**
2. **Microsoft Graph PowerShell Modules**:
   ```powershell
   Install-Module Microsoft.Graph.Authentication -Force
   Install-Module Microsoft.Graph.Users -Force
   Install-Module Microsoft.Graph.Groups -Force
   Install-Module Microsoft.Graph.DeviceManagement -Force
   ```

3. **Appropriate Permissions**:
   - Microsoft Graph permissions for user and group management
   - `RoleManagement.ReadWrite.Directory` scope for role-assignable groups
   - Windows 365 Administrator role or equivalent
   - License assignment permissions
   - For role-assignable groups: Azure AD Premium P1 or P2 license required

4. **Windows 365 Licenses**:
   - Available Windows 365 licenses in your tenant
   - Appropriate Azure subscription for Cloud PC resources

## 🚀 Installation

1. **Clone or Download the Repository**:
   ```powershell
   git clone https://github.com/your-org/win365-lab-builder.git
   cd win365-lab-builder
   ```

2. **Import the Module**:
   ```powershell
   Import-Module .\W365LabBuilder\W365LabBuilder.psd1
   ```

3. **Verify Installation**:
   ```powershell
   Get-Module W365LabBuilder
   Get-Command -Module W365LabBuilder
   ```

## ⚡ Quick Start

Here's how to create a complete Windows 365 lab environment in minutes:

```powershell
# 1. Import the module
Import-Module .\W365LabBuilder\W365LabBuilder.psd1

# 2. Connect to Microsoft Graph
Connect-LabGraph

# 3. Create a complete lab environment (10 users, individual groups, policies)
$labEnvironment = New-LabEnvironment -UserCount 10 -CreateIndividualGroups -CreateProvisioningPolicies -AssignPolicies

# 4. View the results
Write-Host "Successfully created:"
Write-Host "  Users: $($labEnvironment.Users.Count)"
Write-Host "  Groups: $($labEnvironment.Groups.Count)" 
Write-Host "  Policies: $($labEnvironment.Policies.Count)"

# 5. Export user credentials (includes random passwords)
$labEnvironment.Users | Export-Csv "LabCredentials.csv" -NoTypeInformation

# 6. When finished, clean up the environment
Remove-LabEnvironment -UserPrefix "labuser" -RemovePolicies -RemoveGroups -RemoveUsers -Force

# 7. Disconnect
Disconnect-LabGraph
```

## 📚 Function Reference

The Windows 365 Lab Builder includes 30 functions organized into logical categories:

### Authentication Functions
- `Connect-LabGraph` - Connect to Microsoft Graph
- `Disconnect-LabGraph` - Disconnect from Microsoft Graph  
- `Test-LabGraphConnection` - Test Graph connectivity

### User Management Functions
- `New-LabUser` - Create lab users with random passwords
- `Remove-LabUser` - Remove lab users
- `Get-LabUser` - Retrieve user information

### Group Management Functions
- `New-LabGroup` - Create security groups (including role-assignable groups)
- `Remove-LabGroup` - Remove groups
- `Get-LabGroup` - Retrieve group information
- `Add-LabUserToGroup` - Add users to groups
- `Add-LabGroupToRole` - Assign Entra ID directory roles to groups
- `Remove-LabUserFromGroup` - Remove users from groups
- `Set-LabGroupLicense` - Assign licenses to groups
- `Remove-LabGroupLicense` - Remove group licenses
- `Get-LabGroupLicense` - View group license assignments
- `Get-LabAvailableLicense` - List available licenses

### Cloud PC Policy Functions
- `New-LabCloudPCPolicy` - Create provisioning policies
- `Remove-LabCloudPCPolicy` - Remove provisioning policies
- `Get-LabCloudPCPolicy` - List provisioning policies
- `Set-LabPolicyAssignment` - Assign policies to groups
- `Remove-LabPolicyAssignment` - Remove policy assignments

### Cloud PC User Settings Functions
- `New-LabCloudPCUserSettings` - Create user settings policies
- `Remove-LabCloudPCUserSettings` - Remove user settings policies
- `Get-LabCloudPCUserSettings` - List user settings policies
- `Set-LabUserSettingsAssignment` - Assign user settings to groups
- `Remove-LabUserSettingsAssignment` - Remove user settings assignments

### Cloud PC Management Functions
- `Get-LabCloudPC` - Monitor Cloud PC status
- `Stop-LabCloudPCGracePeriod` - End Cloud PC grace periods

### Environment Orchestration Functions
- `New-LabEnvironment` - Create complete lab environments
- `Remove-LabEnvironment` - Clean up lab environments
- `Get-LabEnvironmentStatus` - Monitor environment status

## 💡 Examples

### Basic Lab Creation
```powershell
# Create 5 users with default settings
$users = New-LabUser -UserCount 5

# Create a shared group for all users
$group = New-LabGroup -GroupName "Training Lab"

# Add all users to the group
foreach ($user in $users) {
    Add-LabUserToGroup -UserPrincipalName $user.UserPrincipalName -GroupId $group.Id
}
```

### Advanced Lab with Policies
```powershell
# Create complete environment with custom settings
$lab = New-LabEnvironment -UserCount 20 -UserPrefix "demo" -CreateIndividualGroups -CreateProvisioningPolicies -CreateUserSettingsPolicies -AssignPolicies -RegionName "westus2"

# Export credentials for distribution
$lab.Users | Select-Object DisplayName, UserPrincipalName, Password | Export-Csv "DemoLabCredentials.csv"
```

### License Management
```powershell
# View available licenses
Get-LabAvailableLicense

# Assign specific license to group
Set-LabGroupLicense -GroupName "Lab Group 1" -SkuPartNumber "ENTERPRISEPACK"

# Check group license status
Get-LabGroupLicense -GroupName "Lab Group 1"
```

### Role-Assignable Groups and Directory Roles
```powershell
# Create a role-assignable group (requires Azure AD Premium P1/P2)
$adminGroup = New-LabGroup -GroupName "IT Administrators" -IsAssignableToRole

# Assign an Entra ID directory role to the group
Add-LabGroupToRole -GroupName "IT Administrators" -RoleName "User Administrator"

# Add users to the role-assignable group
Add-LabUserToGroup -UserPrincipalName "admin001@contoso.com" -GroupName "IT Administrators"

# Create multiple role-assignable groups with different roles
$helpdesk = New-LabGroup -GroupName "Helpdesk Team" -IsAssignableToRole
Add-LabGroupToRole -GroupName "Helpdesk Team" -RoleName "Helpdesk Administrator"

$security = New-LabGroup -GroupName "Security Team" -IsAssignableToRole
Add-LabGroupToRole -GroupName "Security Team" -RoleName "Security Reader"
```

## ⚙️ Configuration

The module includes several configuration options that can be customized:

### Default Settings
```powershell
# Module defaults (can be overridden in function calls)
UserPrefix = "labuser"
GroupPrefix = "Lab Group" 
DefaultPassword = "LabPass2025!!"
DefaultUsageLocation = "US"
DefaultRegion = "eastus"
DefaultImageId = "microsoftwindowsdesktop_windows-ent-cpc_win11-24H2-ent-cpc-m365"
MaxUsers = 1000
```

### Configuration File
You can create a configuration file based on `W365LabBuilder/config.example.psd1`:

```powershell
# Copy and customize the configuration
Copy-Item ".\W365LabBuilder\config.example.psd1" ".\W365LabBuilder\config.psd1"
# Edit config.psd1 with your preferred settings
```

## 🔧 Troubleshooting

### Common Issues

**Authentication Problems**:
```powershell
# Test connection
Test-LabGraphConnection

# Reconnect if needed
Disconnect-LabGraph
Connect-LabGraph
```

**Permission Errors**:
- Ensure you have appropriate Graph API permissions
- Verify Windows 365 Administrator role assignment
- Check license availability in your tenant

**Module Import Issues**:
```powershell
# Verify required modules are installed
Get-Module Microsoft.Graph.* -ListAvailable

# Import with force if needed
Import-Module .\W365LabBuilder\W365LabBuilder.psd1 -Force
```

### Getting Help
```powershell
# Get detailed help for any function
Get-Help New-LabEnvironment -Full
Get-Help Connect-LabGraph -Examples
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `.\build.ps1 -Test`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 🔗 Related Resources

- [Windows 365 Documentation](https://docs.microsoft.com/en-us/windows-365/)
- [Microsoft Graph PowerShell](https://docs.microsoft.com/en-us/powershell/microsoftgraph/)
- [Azure AD PowerShell Migration](https://docs.microsoft.com/en-us/powershell/azure/active-directory/migration/)

---

**Windows 365 Lab Builder** - Simplifying Cloud PC lab management for IT professionals, trainers, and developers.

## 📁 Repository Structure

```
win365-lab-builder/
├── README.md                                    # This documentation
├── CONTRIBUTING.md                              # Contribution guidelines
├── CHANGELOG.md                                 # Version history and changes
├── LICENSE                                      # MIT License
├── build.ps1                                    # Build and test automation
├── Examples/                                    # PowerShell example scripts
│   ├── BasicLabSetup.ps1                      # Simple lab creation examples
│   ├── AdvancedLabManagement.ps1              # Complex scenarios
│   └── CleanupLab.ps1                         # Environment cleanup examples
└── W365LabBuilder/                            # Main PowerShell Module
    ├── W365LabBuilder.psd1                   # Module manifest
    ├── W365LabBuilder.psm1                   # Main module file (30 functions)
    ├── README.md                              # Module-specific documentation
    ├── config.example.psd1                    # Configuration template
    ├── Tests/                                 # Pester test suite
    │   └── W365LabBuilder.Tests.ps1         # Comprehensive tests
    └── Examples/                              # Module example scripts
        ├── BasicLabSetup.ps1                 # Basic lab creation
        ├── AdvancedLabManagement.ps1         # Advanced scenarios
        ├── LicenseManagement.ps1             # License operations
        └── UserSettingsManagement.ps1        # User settings policies
```

