# Changelog

All notable changes to the Windows 365 Lab Builder will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-15

### Added
- Initial public release of Windows 365 Lab Builder
- Complete PowerShell module for managing Windows 365 lab environments
- 30 comprehensive functions organized by category:
  - **Authentication Functions** (3): Connect-LabGraph, Disconnect-LabGraph, Test-LabGraphConnection
  - **User Management Functions** (3): New-LabUser, Remove-LabUser, Get-LabUser
  - **Group Management Functions** (4): New-LabGroup, Remove-LabGroup, Get-LabGroup, Add-LabUserToGroup
  - **License Management Functions** (4): Set-LabGroupLicense, Remove-LabGroupLicense, Get-LabGroupLicense, Get-LabAvailableLicense
  - **Cloud PC Provisioning Functions** (4): New-LabCloudPCPolicy, Remove-LabCloudPCPolicy, Get-LabCloudPCPolicy, Set-LabPolicyAssignment
  - **User Settings Functions** (5): New-LabCloudPCUserSettings, Remove-LabCloudPCUserSettings, Get-LabCloudPCUserSettings, Set-LabUserSettingsAssignment, Remove-LabUserSettingsAssignment
  - **Cloud PC Lifecycle Functions** (2): Get-LabCloudPC, Stop-LabCloudPCGracePeriod
  - **Orchestration Functions** (5): New-LabEnvironment, Remove-LabEnvironment, Export-LabCredentials, Import-LabConfig, Test-LabEnvironment

### Features
- **Random Password Generation**: Secure, unique passwords for each user with configurable complexity
- **Enterprise Security**: Built-in security best practices and validation
- **Cross-Platform Support**: Works on Windows, Linux, and macOS with automatic device code authentication
- **Comprehensive Examples**: 7 example scripts covering common scenarios
- **Complete Documentation**: Detailed PowerShell help, README files, and quick start guides
- **Configuration Support**: Customizable defaults via configuration files
- **Error Handling**: Robust error handling and validation throughout
- **Test Coverage**: Comprehensive Pester test suite for reliability

### Documentation
- Complete README with installation and usage instructions
- Quick Start guide for immediate productivity
- Feature-specific guides for advanced scenarios
- PowerShell comment-based help for all functions
- Example scripts covering real-world use cases
- Contributing guidelines and development setup

### Prerequisites
- PowerShell 5.1 or later (PowerShell Core 6+ recommended)
- Microsoft Graph PowerShell modules:
  - Microsoft.Graph.Authentication
  - Microsoft.Graph.Users
  - Microsoft.Graph.Groups
  - Microsoft.Graph.DeviceManagement
- Appropriate Microsoft 365 and Windows 365 licenses
- Global Administrator or equivalent permissions in Azure AD

### Configuration
- Default user prefix: "lu" (lab user)
- Default password: "Lab2024!!"
- Default region: "eastus"
- Maximum users per operation: 1000
- Configurable via config.psd1 file

[Unreleased]: https://github.com/your-org/win365-lab-builder/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/your-org/win365-lab-builder/releases/tag/v1.0.0