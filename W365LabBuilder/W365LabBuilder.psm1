#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users, Microsoft.Graph.Groups, Microsoft.Graph.DeviceManagement

<#
.SYNOPSIS
    Windows 365 Lab Builder Module for managing Windows 365 lab environments

.DESCRIPTION
    This module provides comprehensive functions for managing Windows 365 lab environments
    including user creation, group management, and Cloud PC provisioning policies.

.AUTHOR
    Windows 365 Lab Builder Team

.COPYRIGHT
    Copyright (c) Microsoft Corporation. All rights reserved.
#>

# Import required modules
try {
    Import-Module Microsoft.Graph.Authentication -Force -ErrorAction Stop
    Import-Module Microsoft.Graph.Users -Force -ErrorAction Stop
    Import-Module Microsoft.Graph.Groups -Force -ErrorAction Stop
    Import-Module Microsoft.Graph.DeviceManagement -Force -ErrorAction Stop
}
catch {
    throw "Failed to import required Microsoft Graph modules. Please ensure Microsoft Graph PowerShell modules are installed."
}

# Module variables
$Script:LabGraphConnection = $null
$Script:DefaultDomain = $null
$Script:DefaultTenantId = $null

# Default configuration values
$Script:LabDefaults = @{
    UserPrefix = "labuser"
    GroupPrefix = "Lab Group"
    LicenseGroupName = "LabLicenseGroup"
    RoleGroupName = "LabRoleGroup"
    DefaultPassword = "LabPass2025!!"
    DefaultUsageLocation = "US"
    DefaultRegion = "eastus"
    DefaultTimeZone = "Pacific Standard Time"
    DefaultLanguage = "en-US"
    DefaultImageId = "microsoftwindowsdesktop_windows-ent-cpc_win11-24H2-ent-cpc-m365"
    DefaultImageDisplay = "Windows 11 Enterprise + Microsoft 365 Apps 24H2"
    MaxUsers = 1000
}

#region Authentication Functions

<#
.SYNOPSIS
    Connects to Microsoft Graph with appropriate scopes for lab management.

.DESCRIPTION
    Establishes a connection to Microsoft Graph with necessary scopes for managing
    users, groups, and Cloud PC resources in lab environments. Automatically detects
    Linux environments and uses device code authentication when appropriate.

.PARAMETER TenantId
    The Azure AD tenant ID to connect to. If not specified, uses the default tenant.

.PARAMETER Scopes
    Custom scopes to request. Default scopes include:
    - User.ReadWrite.All
    - Group.ReadWrite.All
    - Directory.ReadWrite.All
    - DeviceManagementConfiguration.ReadWrite.All
    - DeviceManagementManagedDevices.ReadWrite.All

.PARAMETER Force
    Forces a new connection even if already connected.

.PARAMETER UseDeviceCode
    Uses device code authentication (recommended for Linux/remote sessions or if browser auth fails).

.EXAMPLE
    Connect-LabGraph
    Connects using default scopes (auto-detects Linux for device code).

.EXAMPLE
    Connect-LabGraph -TenantId "your-tenant-id-here"
    Connects to a specific tenant.

.EXAMPLE
    Connect-LabGraph -UseDeviceCode
    Explicitly uses device code authentication.

.EXAMPLE
    Connect-LabGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All"
    Connects with custom scopes only.

.NOTES
    This function requires PowerShell 5.1 or later and Microsoft Graph PowerShell modules.
    On Linux systems, device code authentication is automatically used.
    If you encounter authentication issues, try: Connect-LabGraph -UseDeviceCode
#>
function Connect-LabGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Scopes = @(
            "User.ReadWrite.All",
            "Group.ReadWrite.All",
            "Directory.ReadWrite.All",
            "DeviceManagementConfiguration.ReadWrite.All",
            "DeviceManagementManagedDevices.ReadWrite.All"
        ),
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseDeviceCode
    )
    
    begin {
        Write-Verbose "Starting Microsoft Graph connection process"
    }
    
    process {
        try {
            # Check existing connection
            if (-not $Force) {
                $existingConnection = Get-MgContext -ErrorAction SilentlyContinue
                if ($existingConnection) {
                    Write-Information "Already connected to Microsoft Graph as: $($existingConnection.Account)" -InformationAction Continue
                    $Script:LabGraphConnection = $existingConnection
                    
                    # Update default domain if not set
                    if (-not $Script:DefaultDomain) {
                        try {
                            $Script:DefaultDomain = (Get-MgDomain | Where-Object { $_.IsInitial -eq $true }).Id
                        }
                        catch {
                            Write-Verbose "Could not retrieve default domain"
                        }
                    }
                    
                    return $existingConnection
                }
            }
            
            # Connect to Graph
            Write-Information "Connecting to Microsoft Graph..." -InformationAction Continue
            
            $connectParams = @{
                Scopes = $Scopes
            }
            
            if ($TenantId) {
                $connectParams.TenantId = $TenantId
                $Script:DefaultTenantId = $TenantId
            }
            
            # Use device code authentication if requested or on Linux
            if ($UseDeviceCode -or $IsLinux) {
                Write-Host "`nTo sign in, use device code authentication." -ForegroundColor Cyan
                Write-Host "A code and URL will be displayed below. Open the URL in a browser and enter the code.`n" -ForegroundColor Yellow
                $connectParams.UseDeviceCode = $true
            }
            
            # Connect (don't suppress output for device code flow)
            Connect-MgGraph @connectParams
            $Script:LabGraphConnection = Get-MgContext
            
            # Get default domain
            try {
                $Script:DefaultDomain = (Get-MgDomain | Where-Object { $_.IsInitial -eq $true }).Id
            }
            catch {
                Write-Warning "Could not retrieve default domain. You may need to specify domain in function calls."
            }
            
            Write-Information "Successfully connected to Microsoft Graph" -InformationAction Continue
            Write-Information "Connected as: $($Script:LabGraphConnection.Account)" -InformationAction Continue
            if ($Script:DefaultDomain) {
                Write-Information "Default domain: $Script:DefaultDomain" -InformationAction Continue
            }
            
            return $Script:LabGraphConnection
        }
        catch {
            $errorMsg = "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
            Write-Error $errorMsg
            
            # Provide helpful troubleshooting info
            if ($_.Exception.Message -like "*InteractiveBrowserCredential*" -or $_.Exception.Message -like "*authentication*") {
                Write-Warning "`nTroubleshooting tips:"
                Write-Warning "1. Try device code authentication: Connect-LabGraph -UseDeviceCode"
                Write-Warning "2. Connect without custom scopes: Connect-MgGraph (then use lab functions)"
                Write-Warning "3. Ensure Microsoft.Graph modules are up to date: Update-Module Microsoft.Graph"
            }
            
            throw $errorMsg
        }
    }
}

<#
.SYNOPSIS
    Disconnects from Microsoft Graph.

.DESCRIPTION
    Cleanly disconnects the current Microsoft Graph session and clears cached connection information.

.EXAMPLE
    Disconnect-LabGraph

.NOTES
    This function should be called when lab operations are complete to properly clean up the session.
#>
function Disconnect-LabGraph {
    [CmdletBinding()]
    param()
    
    try {
        if ($Script:LabGraphConnection) {
            Disconnect-MgGraph -ErrorAction Stop
            $Script:LabGraphConnection = $null
            $Script:DefaultDomain = $null
            Write-Information "Successfully disconnected from Microsoft Graph" -InformationAction Continue
        }
        else {
            Write-Warning "No active Microsoft Graph connection found"
        }
    }
    catch {
        Write-Error "Failed to disconnect from Microsoft Graph: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Tests the current Microsoft Graph connection.

.DESCRIPTION
    Verifies that there is an active Microsoft Graph connection with appropriate permissions.

.OUTPUTS
    System.Boolean
    Returns $true if connected with valid permissions, $false otherwise.

.EXAMPLE
    if (Test-LabGraphConnection) {
        Write-Host "Ready to perform lab operations"
    }

.NOTES
    This function is used internally by other module functions to ensure connectivity.
#>
function Test-LabGraphConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    try {
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $context) {
            Write-Warning "Not connected to Microsoft Graph. Use Connect-LabGraph to establish connection."
            return $false
        }
        
        # Test basic read permission
        $null = Get-MgDomain -Top 1 -ErrorAction Stop
        $Script:LabGraphConnection = $context
        return $true
    }
    catch {
        Write-Warning "Microsoft Graph connection test failed: $($_.Exception.Message)"
        return $false
    }
}

#endregion Authentication Functions

#region User Management Functions

<#
.SYNOPSIS
    Generates a random secure password for lab users.

.DESCRIPTION
    Creates a cryptographically random password meeting Azure AD complexity requirements.
    Passwords are 16 characters long and include uppercase, lowercase, numbers, and symbols.

.OUTPUTS
    System.String - A random password string.

.NOTES
    Internal helper function for user creation.
#>
function New-RandomPassword {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    # Define character sets for password generation
    $uppercase = 'ABCDEFGHJKLMNPQRSTUVWXYZ'  # Removed I, O for clarity
    $lowercase = 'abcdefghijkmnopqrstuvwxyz'  # Removed l for clarity
    $numbers = '23456789'  # Removed 0, 1 for clarity
    $symbols = '!@#$%^&*'
    
    # Generate password with guaranteed complexity
    $password = ""
    
    # Ensure at least one from each character set
    $password += $uppercase[(Get-Random -Minimum 0 -Maximum $uppercase.Length)]
    $password += $uppercase[(Get-Random -Minimum 0 -Maximum $uppercase.Length)]
    $password += $lowercase[(Get-Random -Minimum 0 -Maximum $lowercase.Length)]
    $password += $lowercase[(Get-Random -Minimum 0 -Maximum $lowercase.Length)]
    $password += $numbers[(Get-Random -Minimum 0 -Maximum $numbers.Length)]
    $password += $numbers[(Get-Random -Minimum 0 -Maximum $numbers.Length)]
    $password += $symbols[(Get-Random -Minimum 0 -Maximum $symbols.Length)]
    $password += $symbols[(Get-Random -Minimum 0 -Maximum $symbols.Length)]
    
    # Fill remaining characters (total 16 chars)
    $allChars = $uppercase + $lowercase + $numbers + $symbols
    for ($i = 8; $i -lt 16; $i++) {
        $password += $allChars[(Get-Random -Minimum 0 -Maximum $allChars.Length)]
    }
    
    # Shuffle the password characters
    $passwordArray = $password.ToCharArray()
    $shuffledPassword = ($passwordArray | Get-Random -Count $passwordArray.Length) -join ''
    
    return $shuffledPassword
}

<#
.SYNOPSIS
    Creates a new lab user with standardized naming and configuration.

.DESCRIPTION
    Creates one or more lab users with consistent naming patterns, password policies,
    and group assignments suitable for lab environments. By default, generates a unique
    random password for each user. Use -UseDefaultPassword to assign the same default
    password to all users.

.PARAMETER UserCount
    Number of users to create. Default is 1.

.PARAMETER UserPrefix
    Prefix for username generation. Default is "iu".

.PARAMETER StartNumber
    Starting number for user sequence. Default is 1.

.PARAMETER Domain
    Domain for user principal names. If not specified, uses the tenant's default domain.

.PARAMETER UseDefaultPassword
    If specified, uses the default password (LabPass2025!!) for all users instead of generating
    random passwords. Random passwords are generated by default for better security.

.PARAMETER UsageLocation
    Usage location for licensing. Default is "US".

.PARAMETER AddToLicenseGroup
    Adds users to the default license group.

.PARAMETER AddToRoleGroup
    Adds users to the default role group.

.PARAMETER ReturnPasswords
    Returns password information along with user objects. Creates custom objects with
    UserPrincipalName, DisplayName, and Password properties.

.EXAMPLE
    New-LabUser -UserCount 10
    Creates 10 users with random passwords.

.EXAMPLE
    New-LabUser -UserCount 5 -UseDefaultPassword
    Creates 5 users with the default password "LabPass2025!!".

.EXAMPLE
    $users = New-LabUser -UserCount 10 -ReturnPasswords
    $users | Export-Csv -Path "UserCredentials.csv" -NoTypeInformation
    Creates 10 users with random passwords and exports credentials to CSV.

.EXAMPLE
    New-LabUser -UserPrefix "TestUser" -UserCount 5 -StartNumber 100 -UseDefaultPassword

.OUTPUTS
    Array of created user objects, or custom objects with password information if -ReturnPasswords is specified.

.NOTES
    Requires User.ReadWrite.All and Directory.ReadWrite.All permissions.
    Random passwords are 16 characters long and meet Azure AD complexity requirements.
    Store passwords securely - they cannot be retrieved after creation.
#>
function New-LabUser {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser[]])]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]$UserCount = 1,
        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrefix = $Script:LabDefaults.UserPrefix,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 9999)]
        [int]$StartNumber = 1,
        
        [Parameter(Mandatory = $false)]
        [string]$Domain,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseDefaultPassword,
        
        [Parameter(Mandatory = $false)]
        [ValidateLength(2, 2)]
        [string]$UsageLocation = $Script:LabDefaults.DefaultUsageLocation,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddToLicenseGroup,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddToRoleGroup,
        
        [Parameter(Mandatory = $false)]
        [switch]$ReturnPasswords
    )
    
    begin {
        Write-Verbose "Starting New-LabUser function"
        
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
        
        # Determine password strategy
        if ($UseDefaultPassword) {
            Write-Information "Using default password for all users" -InformationAction Continue
        }
        else {
            Write-Information "Generating random passwords for each user" -InformationAction Continue
        }
        
        # Set domain if not provided
        if (-not $Domain) {
            $Domain = $Script:DefaultDomain
            if (-not $Domain) {
                throw "Domain not specified and default domain not available. Ensure Graph connection is established."
            }
        }
        
        # Get license and role groups if needed
        $licenseGroup = $null
        $roleGroup = $null
        
        if ($AddToLicenseGroup) {
            $licenseGroup = Get-MgGroup -Filter "displayName eq '$($Script:LabDefaults.LicenseGroupName)'" -ErrorAction SilentlyContinue
            if (-not $licenseGroup) {
                Write-Warning "License group '$($Script:LabDefaults.LicenseGroupName)' not found. Users will not be added to license group."
                $AddToLicenseGroup = $false
            }
        }
        
        if ($AddToRoleGroup) {
            $roleGroup = Get-MgGroup -Filter "displayName eq '$($Script:LabDefaults.RoleGroupName)'" -ErrorAction SilentlyContinue
            if (-not $roleGroup) {
                Write-Warning "Role group '$($Script:LabDefaults.RoleGroupName)' not found. Users will not be added to role group."
                $AddToRoleGroup = $false
            }
        }
        
        $createdUsers = @()
        $userCredentials = @()
        $successCount = 0
        $failureCount = 0
    }
    
    process {
        for ($i = $StartNumber; $i -lt ($StartNumber + $UserCount); $i++) {
            try {
                $userNumber = $i.ToString("D3")
                $displayName = "Lab User $userNumber"
                $username = "$UserPrefix$userNumber"
                $upn = "$username@$Domain"
                
                # Generate or use default password
                if ($UseDefaultPassword) {
                    $userPassword = $Script:LabDefaults.DefaultPassword
                }
                else {
                    $userPassword = New-RandomPassword
                }
                
                Write-Verbose "Creating user: $upn"
                
                # Check if user already exists
                $existingUser = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
                if ($existingUser) {
                    Write-Warning "User $upn already exists. Skipping creation."
                    continue
                }
                
                if ($PSCmdlet.ShouldProcess($upn, "Create Lab User")) {
                    # Create password profile
                    $passwordProfile = @{
                        Password = $userPassword
                        ForceChangePasswordNextSignIn = $false
                    }
                    
                    # Create user
                    $userParams = @{
                        DisplayName = $displayName
                        UserPrincipalName = $upn
                        MailNickname = $username
                        PasswordProfile = $passwordProfile
                        AccountEnabled = $true
                        UsageLocation = $UsageLocation
                        ErrorAction = 'Stop'
                    }
                    
                    $newUser = New-MgUser @userParams
                    Write-Information "Created user: $upn" -InformationAction Continue
                    
                    # Store credentials if requested
                    if ($ReturnPasswords) {
                        $userCredentials += [PSCustomObject]@{
                            UserPrincipalName = $upn
                            DisplayName = $displayName
                            Password = $userPassword
                            Username = $username
                        }
                    }
                    
                    # Add to groups if specified
                    if ($AddToLicenseGroup -and $licenseGroup) {
                        try {
                            New-MgGroupMember -GroupId $licenseGroup.Id -DirectoryObjectId $newUser.Id -ErrorAction Stop
                            Write-Verbose "Added $upn to license group"
                        }
                        catch {
                            Write-Warning "Failed to add $upn to license group: $($_.Exception.Message)"
                        }
                    }
                    
                    if ($AddToRoleGroup -and $roleGroup) {
                        try {
                            New-MgGroupMember -GroupId $roleGroup.Id -DirectoryObjectId $newUser.Id -ErrorAction Stop
                            Write-Verbose "Added $upn to role group"
                        }
                        catch {
                            Write-Warning "Failed to add $upn to role group: $($_.Exception.Message)"
                        }
                    }
                    
                    $createdUsers += $newUser
                    $successCount++
                }
            }
            catch {
                Write-Error "Failed to create user $username : $($_.Exception.Message)"
                $failureCount++
            }
        }
    }
    
    end {
        Write-Information "User creation completed. Success: $successCount, Failed: $failureCount" -InformationAction Continue
        
        if ($ReturnPasswords) {
            Write-Warning "Password information is being returned. Store this data securely!"
            return $userCredentials
        }
        else {
            if (-not $UseDefaultPassword) {
                Write-Warning "Random passwords were generated. Use -ReturnPasswords to capture credentials."
            }
            return $createdUsers
        }
    }
}

<#
.SYNOPSIS
    Removes lab users based on filter criteria.

.DESCRIPTION
    Removes users from the lab environment based on username patterns or specific criteria.
    Includes safety confirmations to prevent accidental deletions.

.PARAMETER UserPrefix
    Prefix to filter users for deletion. Default is "iu".

.PARAMETER UserPrincipalName
    Specific UPN to delete.

.PARAMETER Force
    Bypasses confirmation prompts.

.EXAMPLE
    Remove-LabUser -UserPrefix "lu"

.EXAMPLE
    Remove-LabUser -UserPrincipalName "lu001@contoso.onmicrosoft.com" -Force

.NOTES
    Requires User.ReadWrite.All permission.
#>
function Remove-LabUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = 'ByPrefix')]
        [string]$UserPrefix = $Script:LabDefaults.UserPrefix,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByUPN')]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            if ($PSCmdlet.ParameterSetName -eq 'ByPrefix') {
                # Get users by prefix
                $users = Get-MgUser -All -Filter "startswith(userPrincipalName, '$UserPrefix')" -ErrorAction Stop
                
                if (-not $users) {
                    Write-Information "No users found with prefix '$UserPrefix'" -InformationAction Continue
                    return
                }
                
                Write-Information "Found $($users.Count) users with prefix '$UserPrefix'" -InformationAction Continue
                
                if (-not $Force) {
                    $confirmation = Read-Host "Are you sure you want to delete $($users.Count) users? (yes/no)"
                    if ($confirmation -ne "yes" -and $confirmation -ne "y") {
                        Write-Information "Operation cancelled by user" -InformationAction Continue
                        return
                    }
                }
            }
            else {
                # Get specific user
                $users = @(Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -ErrorAction Stop)
                
                if (-not $users) {
                    Write-Warning "User '$UserPrincipalName' not found"
                    return
                }
            }
            
            $successCount = 0
            $failureCount = 0
            
            foreach ($user in $users) {
                try {
                    if ($PSCmdlet.ShouldProcess($user.UserPrincipalName, "Remove Lab User")) {
                        Remove-MgUser -UserId $user.Id -ErrorAction Stop
                        Write-Information "Deleted user: $($user.UserPrincipalName)" -InformationAction Continue
                        $successCount++
                    }
                }
                catch {
                    Write-Error "Failed to delete user $($user.UserPrincipalName): $($_.Exception.Message)"
                    $failureCount++
                }
            }
            
            Write-Information "User deletion completed. Success: $successCount, Failed: $failureCount" -InformationAction Continue
        }
        catch {
            Write-Error "Failed to remove lab users: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Retrieves lab users based on filter criteria.

.DESCRIPTION
    Gets users from the lab environment with optional filtering by prefix or pattern.

.PARAMETER UserPrefix
    Prefix to filter users. Default is "iu".

.PARAMETER All
    Returns all lab users regardless of prefix.

.EXAMPLE
    Get-LabUser

.EXAMPLE
    Get-LabUser -UserPrefix "TestUser"

.OUTPUTS
    Array of Microsoft Graph user objects.
#>
function Get-LabUser {
    [CmdletBinding()]
    [OutputType([Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$UserPrefix = $Script:LabDefaults.UserPrefix,
        
        [Parameter(Mandatory = $false)]
        [switch]$All
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            if ($All) {
                $users = Get-MgUser -All -ErrorAction Stop
            }
            else {
                $users = Get-MgUser -All -Filter "startswith(userPrincipalName, '$UserPrefix')" -ErrorAction Stop
            }
            
            Write-Information "Found $($users.Count) users" -InformationAction Continue
            return $users
        }
        catch {
            Write-Error "Failed to retrieve lab users: $($_.Exception.Message)"
            throw
        }
    }
}

#endregion User Management Functions

#region Group Management Functions

<#
.SYNOPSIS
    Creates a new lab group with standardized configuration.

.DESCRIPTION
    Creates security groups for lab environments with consistent naming and settings.

.PARAMETER GroupName
    Name of the group to create.

.PARAMETER Description
    Description for the group.

.PARAMETER MailNickname
    Mail nickname for the group. If not specified, derived from group name.

.EXAMPLE
    New-LabGroup -GroupName "Lab Group for user001"

.OUTPUTS
    Microsoft Graph group object.
#>
function New-LabGroup {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([Microsoft.Graph.PowerShell.Models.MicrosoftGraphGroup])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupName,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "Lab group created by Windows 365 Lab Builder",
        
        [Parameter(Mandatory = $false)]
        [string]$MailNickname
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            # Check if group already exists
            $existingGroup = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue
            if ($existingGroup) {
                Write-Warning "Group '$GroupName' already exists"
                return $existingGroup
            }
            
            # Generate mail nickname if not provided
            if (-not $MailNickname) {
                $MailNickname = ($GroupName -replace '[^a-zA-Z0-9]', '').ToLower()
            }
            
            if ($PSCmdlet.ShouldProcess($GroupName, "Create Lab Group")) {
                $groupParams = @{
                    DisplayName = $GroupName
                    Description = $Description
                    MailEnabled = $false
                    MailNickname = $MailNickname
                    SecurityEnabled = $true
                    ErrorAction = 'Stop'
                }
                
                $newGroup = New-MgGroup @groupParams
                Write-Information "Created group: $GroupName" -InformationAction Continue
                return $newGroup
            }
        }
        catch {
            Write-Error "Failed to create group '$GroupName': $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Removes lab groups based on name pattern.

.DESCRIPTION
    Removes groups from the lab environment based on display name patterns.

.PARAMETER GroupNamePattern
    Pattern to match group names for deletion. Default is "*lab group*".

.PARAMETER Force
    Bypasses confirmation prompts.

.EXAMPLE
    Remove-LabGroup

.EXAMPLE
    Remove-LabGroup -GroupNamePattern "TestGroup*" -Force
#>
function Remove-LabGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $false)]
        [string]$GroupNamePattern = "*lab group*",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            # Get all groups and filter by pattern
            $allGroups = Get-MgGroup -All -ErrorAction Stop
            $filteredGroups = $allGroups | Where-Object { $_.DisplayName -like $GroupNamePattern }
            
            if (-not $filteredGroups) {
                Write-Information "No groups found matching pattern '$GroupNamePattern'" -InformationAction Continue
                return
            }
            
            Write-Information "Found $($filteredGroups.Count) groups matching pattern '$GroupNamePattern'" -InformationAction Continue
            
            if (-not $Force) {
                $confirmation = Read-Host "Are you sure you want to delete $($filteredGroups.Count) groups? (yes/no)"
                if ($confirmation -ne "yes" -and $confirmation -ne "y") {
                    Write-Information "Operation cancelled by user" -InformationAction Continue
                    return
                }
            }
            
            $successCount = 0
            $failureCount = 0
            
            foreach ($group in $filteredGroups) {
                try {
                    if ($PSCmdlet.ShouldProcess($group.DisplayName, "Remove Lab Group")) {
                        Remove-MgGroup -GroupId $group.Id -ErrorAction Stop
                        Write-Information "Deleted group: $($group.DisplayName)" -InformationAction Continue
                        $successCount++
                    }
                }
                catch {
                    Write-Error "Failed to delete group $($group.DisplayName): $($_.Exception.Message)"
                    $failureCount++
                }
            }
            
            Write-Information "Group deletion completed. Success: $successCount, Failed: $failureCount" -InformationAction Continue
        }
        catch {
            Write-Error "Failed to remove lab groups: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Retrieves lab groups based on name pattern.

.DESCRIPTION
    Gets groups from the lab environment with optional filtering by name pattern.

.PARAMETER GroupNamePattern
    Pattern to match group names. Default is "*lab*".

.EXAMPLE
    Get-LabGroup

.OUTPUTS
    Array of Microsoft Graph group objects.
#>
function Get-LabGroup {
    [CmdletBinding()]
    [OutputType([Microsoft.Graph.PowerShell.Models.MicrosoftGraphGroup[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$GroupNamePattern = "*lab*"
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            $allGroups = Get-MgGroup -All -ErrorAction Stop
            $filteredGroups = $allGroups | Where-Object { $_.DisplayName -like $GroupNamePattern }
            
            Write-Information "Found $($filteredGroups.Count) groups matching pattern '$GroupNamePattern'" -InformationAction Continue
            return $filteredGroups
        }
        catch {
            Write-Error "Failed to retrieve lab groups: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Adds a user to a lab group.

.DESCRIPTION
    Adds a specified user to a group with error handling and validation.

.PARAMETER UserPrincipalName
    UPN of the user to add to the group.

.PARAMETER GroupName
    Name of the group to add the user to.

.PARAMETER GroupId
    ID of the group to add the user to (alternative to GroupName).

.EXAMPLE
    Add-LabUserToGroup -UserPrincipalName "labuser001@contoso.onmicrosoft.com" -GroupName "Lab Group for labuser001"
#>
function Add-LabUserToGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupName')]
        [string]$GroupName,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupId')]
        [string]$GroupId
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            # Get user
            $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -ErrorAction Stop
            if (-not $user) {
                throw "User '$UserPrincipalName' not found"
            }
            
            # Get group
            if ($PSCmdlet.ParameterSetName -eq 'ByGroupName') {
                $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction Stop
                if (-not $group) {
                    throw "Group '$GroupName' not found"
                }
                $GroupId = $group.Id
            }
            else {
                $group = Get-MgGroup -GroupId $GroupId -ErrorAction Stop
            }
            
            if ($PSCmdlet.ShouldProcess("$UserPrincipalName to $($group.DisplayName)", "Add User to Group")) {
                New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $user.Id -ErrorAction Stop
                Write-Information "Added user $UserPrincipalName to group $($group.DisplayName)" -InformationAction Continue
            }
        }
        catch {
            Write-Error "Failed to add user to group: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Assigns licenses to a group using group-based licensing.

.DESCRIPTION
    Assigns one or more licenses to a security group, which automatically assigns
    those licenses to all members of the group.

.PARAMETER GroupName
    Name of the group to assign licenses to.

.PARAMETER GroupId
    ID of the group to assign licenses to (alternative to GroupName).

.PARAMETER SkuId
    The SKU ID(s) of the license(s) to assign. Can accept multiple SKU IDs.

.PARAMETER SkuPartNumber
    The SKU part number(s) of the license(s) to assign (e.g., "ENTERPRISEPACK", "EMSPREMIUM").

.PARAMETER DisabledPlans
    Optional array of service plan IDs to disable within the license.

.EXAMPLE
    Set-LabGroupLicense -GroupName "LabLicenseGroup" -SkuPartNumber "ENTERPRISEPACK"

.EXAMPLE
    Set-LabGroupLicense -GroupId "group-id" -SkuId "sku-guid"

.EXAMPLE
    Set-LabGroupLicense -GroupName "DemoGroup" -SkuPartNumber "ENTERPRISEPACK","EMSPREMIUM"

.NOTES
    Requires Group.ReadWrite.All and Directory.ReadWrite.All permissions.
    The group must be a security group (not mail-enabled).
#>
function Set-LabGroupLicense {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ByGroupNameAndPartNumber')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupNameAndPartNumber')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupNameAndSkuId')]
        [ValidateNotNullOrEmpty()]
        [string]$GroupName,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupIdAndPartNumber')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupIdAndSkuId')]
        [ValidateNotNullOrEmpty()]
        [string]$GroupId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupNameAndSkuId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupIdAndSkuId')]
        [ValidateNotNullOrEmpty()]
        [string[]]$SkuId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupNameAndPartNumber')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupIdAndPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string[]]$SkuPartNumber,
        
        [Parameter(Mandatory = $false)]
        [string[]]$DisabledPlans = @()
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            # Get group
            if ($PSCmdlet.ParameterSetName -like '*ByGroupName*') {
                $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction Stop
                if (-not $group) {
                    throw "Group '$GroupName' not found"
                }
                $GroupId = $group.Id
            }
            else {
                $group = Get-MgGroup -GroupId $GroupId -ErrorAction Stop
            }
            
            # Get SKU IDs if part numbers were provided
            if ($PSCmdlet.ParameterSetName -like '*PartNumber*') {
                Write-Verbose "Resolving SKU part numbers to SKU IDs..."
                $subscribedSkus = Get-MgSubscribedSku -All -ErrorAction Stop
                $SkuId = @()
                
                foreach ($partNumber in $SkuPartNumber) {
                    $sku = $subscribedSkus | Where-Object { $_.SkuPartNumber -eq $partNumber }
                    if (-not $sku) {
                        Write-Warning "SKU part number '$partNumber' not found in tenant. Available SKUs: $($subscribedSkus.SkuPartNumber -join ', ')"
                        continue
                    }
                    if ($sku.Count -gt 1) {
                        Write-Warning "Multiple SKUs found for part number '$partNumber'. Using first match."
                        $sku = $sku[0]
                    }
                    $SkuId += $sku.SkuId
                    Write-Verbose "Resolved '$partNumber' to SKU ID: $($sku.SkuId)"
                }
                
                if ($SkuId.Count -eq 0) {
                    throw "None of the specified SKU part numbers were found in the tenant"
                }
            }
            
            # Build license assignment parameters
            $assignedLicenses = @()
            foreach ($sku in $SkuId) {
                $licenseParams = @{
                    SkuId = $sku
                }
                
                if ($DisabledPlans.Count -gt 0) {
                    $licenseParams.DisabledPlans = $DisabledPlans
                }
                
                $assignedLicenses += $licenseParams
            }
            
            if ($PSCmdlet.ShouldProcess("$($group.DisplayName)", "Assign $($SkuId.Count) license(s)")) {
                # Set group license assignment
                $params = @{
                    AddLicenses = $assignedLicenses
                    RemoveLicenses = @()
                }
                
                Set-MgGroupLicense -GroupId $GroupId -BodyParameter $params -ErrorAction Stop
                
                Write-Information "Successfully assigned $($SkuId.Count) license(s) to group: $($group.DisplayName)" -InformationAction Continue
                Write-Information "License assignment may take a few minutes to propagate to group members" -InformationAction Continue
            }
        }
        catch {
            Write-Error "Failed to assign licenses to group: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Removes licenses from a group.

.DESCRIPTION
    Removes one or more licenses from a group's license assignment.

.PARAMETER GroupName
    Name of the group to remove licenses from.

.PARAMETER GroupId
    ID of the group to remove licenses from (alternative to GroupName).

.PARAMETER SkuId
    The SKU ID(s) of the license(s) to remove.

.PARAMETER SkuPartNumber
    The SKU part number(s) of the license(s) to remove (e.g., "ENTERPRISEPACK").

.PARAMETER RemoveAll
    Removes all licenses from the group.

.EXAMPLE
    Remove-LabGroupLicense -GroupName "LabLicenseGroup" -SkuPartNumber "ENTERPRISEPACK"

.EXAMPLE
    Remove-LabGroupLicense -GroupId "group-id" -RemoveAll

.NOTES
    Requires Group.ReadWrite.All and Directory.ReadWrite.All permissions.
#>
function Remove-LabGroupLicense {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'ByGroupNameAndPartNumber')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupNameAndPartNumber')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupNameAndSkuId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupNameRemoveAll')]
        [ValidateNotNullOrEmpty()]
        [string]$GroupName,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupIdAndPartNumber')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupIdAndSkuId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupIdRemoveAll')]
        [ValidateNotNullOrEmpty()]
        [string]$GroupId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupNameAndSkuId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupIdAndSkuId')]
        [ValidateNotNullOrEmpty()]
        [string[]]$SkuId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupNameAndPartNumber')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupIdAndPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string[]]$SkuPartNumber,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupNameRemoveAll')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupIdRemoveAll')]
        [switch]$RemoveAll
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            # Get group with license details
            if ($PSCmdlet.ParameterSetName -like '*ByGroupName*') {
                $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -Property "Id,DisplayName,AssignedLicenses" -ErrorAction Stop
                if (-not $group) {
                    throw "Group '$GroupName' not found"
                }
                $GroupId = $group.Id
            }
            else {
                $group = Get-MgGroup -GroupId $GroupId -Property "Id,DisplayName,AssignedLicenses" -ErrorAction Stop
            }
            
            if (-not $group.AssignedLicenses -or $group.AssignedLicenses.Count -eq 0) {
                Write-Warning "Group '$($group.DisplayName)' has no licenses assigned"
                return
            }
            
            # Determine which licenses to remove
            if ($RemoveAll) {
                $SkuId = $group.AssignedLicenses.SkuId
                Write-Information "Removing all $($SkuId.Count) license(s) from group" -InformationAction Continue
            }
            elseif ($PSCmdlet.ParameterSetName -like '*PartNumber*') {
                Write-Verbose "Resolving SKU part numbers to SKU IDs..."
                $subscribedSkus = Get-MgSubscribedSku -All -ErrorAction Stop
                $SkuId = @()
                
                foreach ($partNumber in $SkuPartNumber) {
                    $sku = $subscribedSkus | Where-Object { $_.SkuPartNumber -eq $partNumber }
                    if ($sku) {
                        $SkuId += $sku.SkuId
                    }
                }
            }
            
            if ($PSCmdlet.ShouldProcess("$($group.DisplayName)", "Remove $($SkuId.Count) license(s)")) {
                # Remove licenses
                $params = @{
                    AddLicenses = @()
                    RemoveLicenses = $SkuId
                }
                
                Set-MgGroupLicense -GroupId $GroupId -BodyParameter $params -ErrorAction Stop
                
                Write-Information "Successfully removed $($SkuId.Count) license(s) from group: $($group.DisplayName)" -InformationAction Continue
            }
        }
        catch {
            Write-Error "Failed to remove licenses from group: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Gets license assignments for a group.

.DESCRIPTION
    Retrieves the licenses currently assigned to a group.

.PARAMETER GroupName
    Name of the group to query.

.PARAMETER GroupId
    ID of the group to query (alternative to GroupName).

.EXAMPLE
    Get-LabGroupLicense -GroupName "LabLicenseGroup"

.OUTPUTS
    Array of license assignment objects.
#>
function Get-LabGroupLicense {
    [CmdletBinding(DefaultParameterSetName = 'ByGroupName')]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupName')]
        [ValidateNotNullOrEmpty()]
        [string]$GroupName,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupId')]
        [ValidateNotNullOrEmpty()]
        [string]$GroupId
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            # Get group with license details
            if ($PSCmdlet.ParameterSetName -eq 'ByGroupName') {
                $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -Property "Id,DisplayName,AssignedLicenses" -ErrorAction Stop
                if (-not $group) {
                    throw "Group '$GroupName' not found"
                }
            }
            else {
                $group = Get-MgGroup -GroupId $GroupId -Property "Id,DisplayName,AssignedLicenses" -ErrorAction Stop
            }
            
            if (-not $group.AssignedLicenses -or $group.AssignedLicenses.Count -eq 0) {
                Write-Information "Group '$($group.DisplayName)' has no licenses assigned" -InformationAction Continue
                return @()
            }
            
            # Get SKU details for better output
            $subscribedSkus = Get-MgSubscribedSku -All -ErrorAction Stop
            $licenses = @()
            
            foreach ($assignedLicense in $group.AssignedLicenses) {
                $sku = $subscribedSkus | Where-Object { $_.SkuId -eq $assignedLicense.SkuId }
                
                $licenseInfo = [PSCustomObject]@{
                    GroupName = $group.DisplayName
                    GroupId = $group.Id
                    SkuId = $assignedLicense.SkuId
                    SkuPartNumber = $sku.SkuPartNumber
                    ProductName = $sku.SkuDisplayName
                    DisabledPlans = $assignedLicense.DisabledPlans
                    ConsumedUnits = $sku.ConsumedUnits
                    PrepaidUnits = $sku.PrepaidUnits.Enabled
                }
                
                $licenses += $licenseInfo
            }
            
            Write-Information "Found $($licenses.Count) license(s) assigned to group '$($group.DisplayName)'" -InformationAction Continue
            return $licenses
        }
        catch {
            Write-Error "Failed to retrieve group licenses: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Gets available licenses in the tenant.

.DESCRIPTION
    Retrieves all subscribed SKUs (licenses) available in the tenant with detailed information
    about consumed units, available units, and service plans. This is useful for discovering
    valid SkuPartNumber values to use with Set-LabGroupLicense.

.PARAMETER SkuPartNumber
    Filter results to specific SKU part numbers (e.g., "ENTERPRISEPACK", "EMSPREMIUM").

.PARAMETER IncludeDisabled
    Include licenses with no available units.

.EXAMPLE
    Get-LabAvailableLicense
    Lists all licenses in the tenant.

.EXAMPLE
    Get-LabAvailableLicense -SkuPartNumber "ENTERPRISEPACK"
    Gets details for a specific license.

.EXAMPLE
    Get-LabAvailableLicense | Where-Object AvailableUnits -gt 0
    Lists only licenses with available units.

.EXAMPLE
    Get-LabAvailableLicense | Format-Table SkuPartNumber, ProductName, AvailableUnits
    Lists licenses in a formatted table.

.OUTPUTS
    Array of license (SKU) objects with detailed information.

.NOTES
    Use this function to discover valid SkuPartNumber values before calling Set-LabGroupLicense.
#>
function Get-LabAvailableLicense {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$SkuPartNumber,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDisabled
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            Write-Verbose "Retrieving subscribed SKUs from tenant..."
            $subscribedSkus = Get-MgSubscribedSku -All -ErrorAction Stop
            
            if ($SkuPartNumber) {
                $subscribedSkus = $subscribedSkus | Where-Object { $_.SkuPartNumber -in $SkuPartNumber }
            }
            
            $licenses = @()
            foreach ($sku in $subscribedSkus) {
                $enabled = if ($sku.PrepaidUnits.Enabled) { $sku.PrepaidUnits.Enabled } else { 0 }
                $suspended = if ($sku.PrepaidUnits.Suspended) { $sku.PrepaidUnits.Suspended } else { 0 }
                $warning = if ($sku.PrepaidUnits.Warning) { $sku.PrepaidUnits.Warning } else { 0 }
                $consumed = if ($sku.ConsumedUnits) { $sku.ConsumedUnits } else { 0 }
                
                $available = $enabled + $warning - $consumed
                
                # Skip disabled licenses unless requested
                if (-not $IncludeDisabled -and $available -le 0 -and $enabled -eq 0) {
                    continue
                }
                
                # Get service plan details
                $servicePlans = @()
                foreach ($plan in $sku.ServicePlans) {
                    $servicePlans += [PSCustomObject]@{
                        ServicePlanName = $plan.ServicePlanName
                        ServicePlanId = $plan.ServicePlanId
                        AppliesTo = $plan.AppliesTo
                    }
                }
                
                $licenseInfo = [PSCustomObject]@{
                    SkuPartNumber = $sku.SkuPartNumber
                    SkuId = $sku.SkuId
                    ProductName = $sku.SkuDisplayName
                    ConsumedUnits = $consumed
                    EnabledUnits = $enabled
                    SuspendedUnits = $suspended
                    WarningUnits = $warning
                    AvailableUnits = $available
                    ServicePlans = $servicePlans
                    CapabilityStatus = $sku.CapabilityStatus
                    AppliesTo = $sku.AppliesTo
                }
                
                $licenses += $licenseInfo
            }
            
            Write-Information "Found $($licenses.Count) license(s) in tenant" -InformationAction Continue
            return $licenses | Sort-Object ProductName
        }
        catch {
            Write-Error "Failed to retrieve available licenses: $($_.Exception.Message)"
            throw
        }
    }
}

#endregion Group Management Functions

#region Cloud PC Provisioning Functions

<#
.SYNOPSIS
    Creates a new Cloud PC provisioning policy.

.DESCRIPTION
    Creates a Windows 365 provisioning policy with standardized configuration for lab environments.
    By default, uses Microsoft-hosted network with automatic region selection.
    Optionally, you can specify an Azure network connection ID for Azure network connectivity.

.PARAMETER PolicyName
    Name of the provisioning policy to create.

.PARAMETER Description
    Description for the policy.

.PARAMETER OnPremisesConnectionId
    Optional. The Azure network connection ID for using Azure network connectivity.
    If not specified, the policy will use Microsoft-hosted network with automatic region selection.
    Use Get-MgDeviceManagementVirtualEndpointOnPremisesConnection to find available connections.

.PARAMETER RegionName
    Optional. Specific Azure region for Microsoft-hosted network.
    Valid values: "eastus", "westus", "westus2", "northeurope", "westeurope", "southeastasia", etc.
    If not specified, uses "eastus" (default).
    This parameter is ignored if OnPremisesConnectionId is specified.

.PARAMETER ImageId
    Image ID to use for provisioning. Default is Windows 11 with M365 Apps.
    Format: {publisher}_{offer}_{sku} (e.g., "microsoftwindowsdesktop_windows-ent-cpc_win11-24h2-ent-cpc-m365")

.PARAMETER ImageType
    Type of image: "gallery" or "custom". Default is "gallery".

.PARAMETER Locale
    Windows locale setting (e.g., "en-US", "de-DE", "fr-FR"). Default is "en-US".

.PARAMETER EnableSingleSignOn
    Enable single sign-on for the provisioning policy.

.EXAMPLE
    New-LabCloudPCPolicy -PolicyName "Lab Policy"
    Creates a policy using Microsoft-hosted network with default region (eastus).

.EXAMPLE
    New-LabCloudPCPolicy -PolicyName "Lab Policy" -RegionName "westeurope"
    Creates a policy using Microsoft-hosted network in the West Europe region.

.EXAMPLE
    New-LabCloudPCPolicy -PolicyName "Lab Policy" -OnPremisesConnectionId "connection-id"
    Creates a policy using Azure network connection.

.EXAMPLE
    New-LabCloudPCPolicy -PolicyName "Lab Policy" -EnableSingleSignOn
    Creates a policy with SSO enabled using Microsoft-hosted network.

.OUTPUTS
    Microsoft Graph Cloud PC provisioning policy object.

.NOTES
    Requires CloudPC.ReadWrite.All permission.
    Microsoft-hosted network with eastus region is used by default.
    Use -RegionName to specify a different Azure region for Microsoft-hosted network.
    Use -OnPremisesConnectionId to use Azure network connection instead.
    Valid Azure region names: eastus, westus, westus2, northeurope, westeurope, etc.
#>
function New-LabCloudPCPolicy {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([Microsoft.Graph.PowerShell.Models.MicrosoftGraphCloudPcProvisioningPolicy])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyName,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "Lab provisioning policy created by Windows 365 Lab Builder",
        
        [Parameter(Mandatory = $false)]
        [string]$OnPremisesConnectionId,
        
        [Parameter(Mandatory = $false)]
        [string]$RegionName = "eastus",
        
        [Parameter(Mandatory = $false)]
        [string]$ImageId = $Script:LabDefaults.DefaultImageId,
        
        [Parameter(Mandatory = $false)]
        [string]$ImageDisplayName = $Script:LabDefaults.DefaultImageDisplay,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('gallery', 'custom')]
        [string]$ImageType = 'gallery',
        
        [Parameter(Mandatory = $false)]
        [string]$Locale = $Script:LabDefaults.DefaultLanguage,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableSingleSignOn
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            # Check if policy already exists
            $existingPolicy = Get-MgDeviceManagementVirtualEndpointProvisioningPolicy -Filter "displayName eq '$PolicyName'" -ErrorAction SilentlyContinue
            if ($existingPolicy) {
                Write-Warning "Provisioning policy '$PolicyName' already exists"
                return $existingPolicy
            }
            
            if ($PSCmdlet.ShouldProcess($PolicyName, "Create Cloud PC Provisioning Policy")) {
                # Configure Windows settings (only locale is supported)
                $windowsSettings = @{
                    locale = $Locale
                }
                
                # Configure domain join settings
                $domainJoinConfig = @{
                    domainJoinType = "azureADJoin"
                }
                
                # For Azure AD Join, must specify either onPremisesConnectionId OR regionName
                if ($OnPremisesConnectionId) {
                    # Use Azure network connection
                    $domainJoinConfig.onPremisesConnectionId = $OnPremisesConnectionId
                    Write-Verbose "Using Azure network connection: $OnPremisesConnectionId"
                }
                else {
                    # Use Microsoft-hosted network with region
                    $domainJoinConfig.regionName = $RegionName
                    Write-Verbose "Using Microsoft-hosted network in region: $RegionName"
                }
                
                # Create policy parameters with correct property names
                $policyParams = @{
                    displayName = $PolicyName
                    description = $Description
                    windowsSetting = $windowsSettings
                    domainJoinConfigurations = @($domainJoinConfig)
                    imageId = $ImageId
                    imageDisplayName = $ImageDisplayName
                    imageType = $ImageType
                }
                
                if ($EnableSingleSignOn) {
                    $policyParams.enableSingleSignOn = $true
                }
                
                Write-Verbose "Creating provisioning policy with parameters:"
                Write-Verbose ($policyParams | ConvertTo-Json -Depth 5)
                
                $newPolicy = New-MgDeviceManagementVirtualEndpointProvisioningPolicy -BodyParameter $policyParams -ErrorAction Stop
                Write-Information "Created provisioning policy: $PolicyName" -InformationAction Continue
                return $newPolicy
            }
        }
        catch {
            Write-Error "Failed to create provisioning policy '$PolicyName': $($_.Exception.Message)"
            Write-Verbose "Error details: $($_.Exception)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Removes Cloud PC provisioning policies based on name pattern.

.DESCRIPTION
    Removes Windows 365 provisioning policies from the environment with optional pattern matching.

.PARAMETER PolicyNamePattern
    Pattern to match policy names for deletion. Default is "Lab*".

.PARAMETER PolicyId
    Specific policy ID to delete.

.PARAMETER RemoveAssignments
    Removes all assignments before deleting the policy.

.PARAMETER Force
    Bypasses confirmation prompts.

.EXAMPLE
    Remove-LabCloudPCPolicy

.EXAMPLE
    Remove-LabCloudPCPolicy -PolicyNamePattern "TestPolicy*" -Force
#>
function Remove-LabCloudPCPolicy {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = 'ByPattern')]
        [string]$PolicyNamePattern = "Lab*",
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string]$PolicyId,
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveAssignments,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            if ($PSCmdlet.ParameterSetName -eq 'ByPattern') {
                # Get policies by pattern
                $allPolicies = Get-MgDeviceManagementVirtualEndpointProvisioningPolicy -All -ErrorAction Stop
                $targetPolicies = $allPolicies | Where-Object { $_.DisplayName -like $PolicyNamePattern }
                
                if (-not $targetPolicies) {
                    Write-Information "No provisioning policies found matching pattern '$PolicyNamePattern'" -InformationAction Continue
                    return
                }
                
                Write-Information "Found $($targetPolicies.Count) policies matching pattern '$PolicyNamePattern'" -InformationAction Continue
                
                if (-not $Force) {
                    $confirmation = Read-Host "Are you sure you want to delete $($targetPolicies.Count) provisioning policies? (yes/no)"
                    if ($confirmation -ne "yes" -and $confirmation -ne "y") {
                        Write-Information "Operation cancelled by user" -InformationAction Continue
                        return
                    }
                }
            }
            else {
                # Get specific policy
                $targetPolicies = @(Get-MgDeviceManagementVirtualEndpointProvisioningPolicy -CloudPcProvisioningPolicyId $PolicyId -ErrorAction Stop)
            }
            
            $successCount = 0
            $failureCount = 0
            
            foreach ($policy in $targetPolicies) {
                try {
                    if ($PSCmdlet.ShouldProcess($policy.DisplayName, "Remove Cloud PC Provisioning Policy")) {
                        # Remove assignments if requested
                        if ($RemoveAssignments) {
                            $emptyAssignments = @{
                                assignments = @()
                            }
                            Set-MgDeviceManagementVirtualEndpointProvisioningPolicy -CloudPcProvisioningPolicyId $policy.Id -BodyParameter $emptyAssignments -ErrorAction SilentlyContinue
                            Write-Verbose "Removed assignments for policy: $($policy.DisplayName)"
                        }
                        
                        # Delete the policy
                        Remove-MgDeviceManagementVirtualEndpointProvisioningPolicy -CloudPcProvisioningPolicyId $policy.Id -ErrorAction Stop
                        Write-Information "Deleted provisioning policy: $($policy.DisplayName)" -InformationAction Continue
                        $successCount++
                    }
                }
                catch {
                    Write-Error "Failed to delete policy $($policy.DisplayName): $($_.Exception.Message)"
                    $failureCount++
                }
            }
            
            Write-Information "Policy deletion completed. Success: $successCount, Failed: $failureCount" -InformationAction Continue
        }
        catch {
            Write-Error "Failed to remove Cloud PC provisioning policies: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Retrieves Cloud PC provisioning policies.

.DESCRIPTION
    Gets Windows 365 provisioning policies with optional filtering by name pattern.

.PARAMETER PolicyNamePattern
    Pattern to match policy names. Default is "*".

.EXAMPLE
    Get-LabCloudPCPolicy

.OUTPUTS
    Array of Microsoft Graph Cloud PC provisioning policy objects.
#>
function Get-LabCloudPCPolicy {
    [CmdletBinding()]
    [OutputType([Microsoft.Graph.PowerShell.Models.MicrosoftGraphCloudPcProvisioningPolicy[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$PolicyNamePattern = "*"
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            $allPolicies = Get-MgDeviceManagementVirtualEndpointProvisioningPolicy -All -ErrorAction Stop
            $filteredPolicies = $allPolicies | Where-Object { $_.DisplayName -like $PolicyNamePattern }
            
            Write-Information "Found $($filteredPolicies.Count) policies matching pattern '$PolicyNamePattern'" -InformationAction Continue
            return $filteredPolicies
        }
        catch {
            Write-Error "Failed to retrieve Cloud PC provisioning policies: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Assigns a Cloud PC provisioning policy to a group.

.DESCRIPTION
    Adds a group assignment to a Windows 365 provisioning policy.
    This function adds to existing assignments rather than replacing them.
    If the group is already assigned, the function will skip it and notify you.

.PARAMETER PolicyId
    ID of the provisioning policy to assign.

.PARAMETER GroupId
    ID of the group to assign the policy to.

.PARAMETER GroupName
    Name of the group to assign the policy to (alternative to GroupId).

.EXAMPLE
    Set-LabPolicyAssignment -PolicyId "policy-id" -GroupName "Lab Group for labuser001"
    Adds the specified group to the policy's assignments.

.EXAMPLE
    Set-LabPolicyAssignment -PolicyId "policy-id" -GroupId "group-id"
    Adds the group by ID to the policy's assignments.

.NOTES
    This function preserves existing assignments and adds the new group.
    If the group is already assigned, no changes are made.
#>
function Set-LabPolicyAssignment {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupId')]
        [string]$GroupId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByGroupName')]
        [string]$GroupName
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            # Get group ID if name was provided
            if ($PSCmdlet.ParameterSetName -eq 'ByGroupName') {
                $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction Stop
                if (-not $group) {
                    throw "Group '$GroupName' not found"
                }
                $GroupId = $group.Id
            }
            
            # Get policy to validate it exists
            $policy = Get-MgDeviceManagementVirtualEndpointProvisioningPolicy -CloudPcProvisioningPolicyId $PolicyId -ErrorAction Stop
            
            # Get existing assignments using $expand
            $existingAssignments = @()
            try {
                $uri = "https://graph.microsoft.com/v1.0/deviceManagement/virtualEndpoint/provisioningPolicies/$PolicyId`?`$expand=assignments"
                $policyWithAssignments = Invoke-MgGraphRequest -Uri $uri -Method GET -ErrorAction Stop
                
                Write-Verbose "Policy retrieved with assignments"
                Write-Verbose "Assignments found: $($policyWithAssignments.assignments.Count)"
                
                if ($policyWithAssignments.assignments) {
                    $existingAssignments = $policyWithAssignments.assignments
                }
            }
            catch {
                Write-Verbose "No existing assignments found: $($_.Exception.Message)"
            }
            
            # Check if this group is already assigned
            $alreadyAssigned = $existingAssignments | Where-Object { 
                $_.target.groupId -eq $GroupId 
            }
            
            if ($alreadyAssigned) {
                Write-Information "Group ID $GroupId is already assigned to policy '$($policy.DisplayName)'" -InformationAction Continue
                return
            }
            
            if ($PSCmdlet.ShouldProcess("Policy: $($policy.DisplayName) to Group ID: $GroupId", "Add Policy Assignment")) {
                # Build complete assignments array (existing + new)
                $allAssignments = @()
                
                # Add existing assignments with their IDs
                foreach ($existingAssignment in $existingAssignments) {
                    $assignmentObj = @{
                        target = @{
                            "@odata.type" = "#microsoft.graph.cloudPcManagementGroupAssignmentTarget"
                            groupId = $existingAssignment.target.groupId
                        }
                    }
                    # Include ID if it exists
                    if ($existingAssignment.id) {
                        $assignmentObj.id = $existingAssignment.id
                    }
                    $allAssignments += $assignmentObj
                }
                
                # Add new assignment (no ID for new assignments)
                $allAssignments += @{
                    target = @{
                        "@odata.type" = "#microsoft.graph.cloudPcManagementGroupAssignmentTarget"
                        groupId = $GroupId
                    }
                }
                
                Write-Verbose "Total assignments to set: $($allAssignments.Count)"
                Write-Verbose "Assignment payload: $($allAssignments | ConvertTo-Json -Depth 10)"
                
                # Use the /assign endpoint with POST to set all assignments
                $updateBody = @{
                    assignments = $allAssignments
                }
                
                $uri = "https://graph.microsoft.com/v1.0/deviceManagement/virtualEndpoint/provisioningPolicies/$PolicyId/assign"
                $result = Invoke-MgGraphRequest -Uri $uri -Method POST -Body ($updateBody | ConvertTo-Json -Depth 10) -ContentType "application/json" -ErrorAction Stop
                
                Write-Information "Successfully assigned policy '$($policy.DisplayName)' to group ID: $GroupId (Total assignments: $($allAssignments.Count))" -InformationAction Continue
                Write-Verbose "POST result: $($result | ConvertTo-Json -Depth 5)"
            }
        }
        catch {
            Write-Error "Failed to set policy assignment: $($_.Exception.Message)"
            throw
        }
    }
}

#endregion Cloud PC Provisioning Functions

#region Cloud PC Lifecycle Functions

<#
.SYNOPSIS
    Retrieves Cloud PCs with optional status filtering.

.DESCRIPTION
    Gets Cloud PC information from the environment with optional filtering by status.

.PARAMETER Status
    Filter Cloud PCs by status (e.g., "InGracePeriod", "Provisioned", "Failed").

.PARAMETER All
    Returns all Cloud PCs regardless of status.

.EXAMPLE
    Get-LabCloudPC -Status "InGracePeriod"

.OUTPUTS
    Array of Microsoft Graph Cloud PC objects.
#>
function Get-LabCloudPC {
    [CmdletBinding()]
    [OutputType([Microsoft.Graph.PowerShell.Models.MicrosoftGraphCloudPc[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [switch]$All
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            $cloudPCs = Get-MgBetaDeviceManagementVirtualEndpointCloudPc -All -ErrorAction Stop
            
            if (-not $All -and $Status) {
                $cloudPCs = $cloudPCs | Where-Object { $_.Status -eq $Status }
            }
            
            Write-Information "Found $($cloudPCs.Count) Cloud PCs" -InformationAction Continue
            return $cloudPCs
        }
        catch {
            Write-Error "Failed to retrieve Cloud PCs: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Ends the grace period for Cloud PCs in grace period status.

.DESCRIPTION
    Terminates the grace period for Cloud PCs that are in "InGracePeriod" status.

.PARAMETER CloudPCId
    Specific Cloud PC ID to end grace period for.

.PARAMETER All
    Ends grace period for all Cloud PCs in grace period status.

.PARAMETER Force
    Bypasses confirmation prompts.

.EXAMPLE
    Stop-LabCloudPCGracePeriod -All

.EXAMPLE
    Stop-LabCloudPCGracePeriod -CloudPCId "specific-pc-id" -Force
#>
function Stop-LabCloudPCGracePeriod {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string]$CloudPCId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch]$All,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            if ($PSCmdlet.ParameterSetName -eq 'All') {
                # Get all Cloud PCs in grace period
                $cloudPCs = Get-LabCloudPC -Status "InGracePeriod" -ErrorAction Stop
                
                if (-not $cloudPCs) {
                    Write-Information "No Cloud PCs found in grace period status" -InformationAction Continue
                    return
                }
                
                Write-Information "Found $($cloudPCs.Count) Cloud PCs in grace period" -InformationAction Continue
                
                if (-not $Force) {
                    $confirmation = Read-Host "Are you sure you want to end grace period for $($cloudPCs.Count) Cloud PCs? (yes/no)"
                    if ($confirmation -ne "yes" -and $confirmation -ne "y") {
                        Write-Information "Operation cancelled by user" -InformationAction Continue
                        return
                    }
                }
            }
            else {
                # Get specific Cloud PC
                $cloudPCs = @(Get-MgBetaDeviceManagementVirtualEndpointCloudPc -CloudPCId $CloudPCId -ErrorAction Stop)
            }
            
            $successCount = 0
            $failureCount = 0
            
            foreach ($pc in $cloudPCs) {
                try {
                    if ($PSCmdlet.ShouldProcess($pc.Id, "End Grace Period")) {
                        Stop-MgDeviceManagementVirtualEndpointCloudPcGracePeriod -CloudPCId $pc.Id -ErrorAction Stop
                        Write-Information "Ended grace period for Cloud PC: $($pc.Id)" -InformationAction Continue
                        $successCount++
                    }
                }
                catch {
                    Write-Error "Failed to end grace period for Cloud PC $($pc.Id): $($_.Exception.Message)"
                    $failureCount++
                }
            }
            
            Write-Information "Grace period termination completed. Success: $successCount, Failed: $failureCount" -InformationAction Continue
        }
        catch {
            Write-Error "Failed to stop Cloud PC grace periods: $($_.Exception.Message)"
            throw
        }
    }
}

#endregion Cloud PC Lifecycle Functions

#region Cloud PC User Settings Functions

<#
.SYNOPSIS
    Creates a Windows 365 user settings policy.

.DESCRIPTION
    Creates a user settings policy for Windows 365 that controls features like
    local admin access, self-service options, and restore capabilities.

.PARAMETER PolicyName
    Name of the user settings policy.

.PARAMETER Description
    Description of the user settings policy.

.PARAMETER EnableLocalAdmin
    Enables local administrator access for users. Default is $false.

.PARAMETER EnableSelfServiceRestore
    Enables users to restore their own Cloud PCs. Default is $true.

.PARAMETER RestorePointFrequencyInHours
    Frequency of automatic restore points in hours (4-24). Default is 12.

.EXAMPLE
    New-LabCloudPCUserSettings -PolicyName "Lab User Settings" -EnableLocalAdmin

.EXAMPLE
    New-LabCloudPCUserSettings -PolicyName "Restricted Settings" -EnableLocalAdmin:$false -EnableSelfServiceRestore:$false

.OUTPUTS
    Microsoft.Graph.PowerShell.Models.MicrosoftGraphCloudPcUserSettings
#>
function New-LabCloudPCUserSettings {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([Microsoft.Graph.PowerShell.Models.MicrosoftGraphCloudPcUserSetting])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyName,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "User settings policy for lab environment",
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableLocalAdmin = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableSelfServiceRestore = $true,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(4, 24)]
        [int]$RestorePointFrequencyInHours = 12
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            # Check if policy with same name exists
            $existingPolicies = Get-MgDeviceManagementVirtualEndpointUserSetting -Filter "displayName eq '$PolicyName'" -ErrorAction SilentlyContinue
            if ($existingPolicies) {
                Write-Warning "User settings policy with name '$PolicyName' already exists"
                return $existingPolicies[0]
            }
            
            if ($PSCmdlet.ShouldProcess($PolicyName, "Create Windows 365 User Settings Policy")) {
                # Build user settings parameters
                $userSettingsParams = @{
                    DisplayName = $PolicyName
                    Description = $Description
                    LocalAdminEnabled = $EnableLocalAdmin
                    SelfServiceEnabled = $EnableSelfServiceRestore
                    RestorePointFrequencyInHours = $RestorePointFrequencyInHours
                }
                
                # Create user settings policy
                $policy = New-MgDeviceManagementVirtualEndpointUserSetting -BodyParameter $userSettingsParams -ErrorAction Stop
                
                Write-Information "Successfully created user settings policy: $PolicyName" -InformationAction Continue
                Write-Information "  - Local Admin: $(if($EnableLocalAdmin){'Enabled'}else{'Disabled'})" -InformationAction Continue
                Write-Information "  - Self-Service Restore: $(if($EnableSelfServiceRestore){'Enabled'}else{'Disabled'})" -InformationAction Continue
                Write-Information "  - Restore Point Frequency: $RestorePointFrequencyInHours hours" -InformationAction Continue
                
                return $policy
            }
        }
        catch {
            Write-Error "Failed to create user settings policy: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Removes Windows 365 user settings policies.

.DESCRIPTION
    Removes one or more Windows 365 user settings policies by name pattern or ID.

.PARAMETER PolicyName
    Name or name pattern of the user settings policy to remove.

.PARAMETER PolicyId
    ID of the user settings policy to remove.

.PARAMETER Force
    Bypasses confirmation prompts.

.EXAMPLE
    Remove-LabCloudPCUserSettings -PolicyName "Lab User Settings"

.EXAMPLE
    Remove-LabCloudPCUserSettings -PolicyName "Lab*" -Force

.EXAMPLE
    Remove-LabCloudPCUserSettings -PolicyId "policy-guid" -Force
#>
function Remove-LabCloudPCUserSettings {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyName,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyId,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            # Get target policies
            if ($PSCmdlet.ParameterSetName -eq 'ByName') {
                $allPolicies = Get-MgDeviceManagementVirtualEndpointUserSetting -All -ErrorAction Stop
                
                if ($PolicyName -match '\*') {
                    $pattern = $PolicyName -replace '\*', '.*'
                    $targetPolicies = $allPolicies | Where-Object { $_.DisplayName -match $pattern }
                }
                else {
                    $targetPolicies = $allPolicies | Where-Object { $_.DisplayName -eq $PolicyName }
                }
                
                if (-not $targetPolicies) {
                    Write-Warning "No user settings policies found matching: $PolicyName"
                    return
                }
            }
            else {
                $targetPolicies = @(Get-MgDeviceManagementVirtualEndpointUserSetting -CloudPcUserSettingId $PolicyId -ErrorAction Stop)
            }
            
            Write-Information "Found $($targetPolicies.Count) user settings policy(ies) to remove" -InformationAction Continue
            
            if (-not $Force) {
                $confirmation = Read-Host "Remove $($targetPolicies.Count) user settings policy(ies)? (yes/no)"
                if ($confirmation -ne "yes" -and $confirmation -ne "y") {
                    Write-Information "Operation cancelled" -InformationAction Continue
                    return
                }
            }
            
            $successCount = 0
            $failureCount = 0
            
            foreach ($policy in $targetPolicies) {
                try {
                    if ($PSCmdlet.ShouldProcess($policy.DisplayName, "Remove User Settings Policy")) {
                        # Remove assignments first (if any)
                        try {
                            $emptyAssignments = @{ Assignments = @() }
                            Update-MgDeviceManagementVirtualEndpointUserSetting -CloudPcUserSettingId $policy.Id -BodyParameter $emptyAssignments -ErrorAction SilentlyContinue
                        }
                        catch {
                            Write-Verbose "Could not clear assignments: $($_.Exception.Message)"
                        }
                        
                        # Remove the policy
                        Remove-MgDeviceManagementVirtualEndpointUserSetting -CloudPcUserSettingId $policy.Id -ErrorAction Stop
                        Write-Information "Removed user settings policy: $($policy.DisplayName)" -InformationAction Continue
                        $successCount++
                    }
                }
                catch {
                    Write-Error "Failed to remove policy '$($policy.DisplayName)': $($_.Exception.Message)"
                    $failureCount++
                }
            }
            
            Write-Information "Removal completed. Success: $successCount, Failed: $failureCount" -InformationAction Continue
        }
        catch {
            Write-Error "Failed to remove user settings policies: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Gets Windows 365 user settings policies.

.DESCRIPTION
    Retrieves Windows 365 user settings policies with optional filtering by name pattern.

.PARAMETER PolicyName
    Name or name pattern of the user settings policy to retrieve.

.PARAMETER PolicyId
    ID of the user settings policy to retrieve.

.PARAMETER All
    Returns all user settings policies.

.EXAMPLE
    Get-LabCloudPCUserSettings -All

.EXAMPLE
    Get-LabCloudPCUserSettings -PolicyName "Lab*"

.OUTPUTS
    Array of Microsoft.Graph.PowerShell.Models.MicrosoftGraphCloudPcUserSetting objects.
#>
function Get-LabCloudPCUserSettings {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([Microsoft.Graph.PowerShell.Models.MicrosoftGraphCloudPcUserSetting[]])]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = 'ByName')]
        [string]$PolicyName,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'ById')]
        [string]$PolicyId,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [switch]$All
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            if ($PSCmdlet.ParameterSetName -eq 'ById') {
                $policies = @(Get-MgDeviceManagementVirtualEndpointUserSetting -CloudPcUserSettingId $PolicyId -ErrorAction Stop)
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'ByName') {
                $allPolicies = Get-MgDeviceManagementVirtualEndpointUserSetting -All -ErrorAction Stop
                
                if ($PolicyName -match '\*') {
                    $pattern = $PolicyName -replace '\*', '.*'
                    $policies = $allPolicies | Where-Object { $_.DisplayName -match $pattern }
                }
                else {
                    $policies = $allPolicies | Where-Object { $_.DisplayName -eq $PolicyName }
                }
            }
            else {
                $policies = Get-MgDeviceManagementVirtualEndpointUserSetting -All -ErrorAction Stop
            }
            
            Write-Information "Found $($policies.Count) user settings policy(ies)" -InformationAction Continue
            return $policies
        }
        catch {
            Write-Error "Failed to retrieve user settings policies: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Assigns a Windows 365 user settings policy to groups.

.DESCRIPTION
    Creates group assignments for Windows 365 user settings policies.

.PARAMETER PolicyId
    ID of the user settings policy to assign.

.PARAMETER PolicyName
    Name of the user settings policy to assign.

.PARAMETER GroupId
    ID(s) of the group(s) to assign the policy to.

.PARAMETER GroupName
    Name(s) of the group(s) to assign the policy to.

.EXAMPLE
    Set-LabUserSettingsAssignment -PolicyName "Lab User Settings" -GroupName "LabLicenseGroup"

.EXAMPLE
    Set-LabUserSettingsAssignment -PolicyId "policy-guid" -GroupId "group-guid1","group-guid2"
#>
function Set-LabUserSettingsAssignment {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ByPolicyNameAndGroupName')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPolicyIdAndGroupId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPolicyIdAndGroupName')]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPolicyNameAndGroupId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPolicyNameAndGroupName')]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyName,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPolicyIdAndGroupId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPolicyNameAndGroupId')]
        [ValidateNotNullOrEmpty()]
        [string[]]$GroupId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPolicyIdAndGroupName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPolicyNameAndGroupName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$GroupName
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            # Get policy
            if ($PSCmdlet.ParameterSetName -like '*ByPolicyName*') {
                $policy = Get-MgDeviceManagementVirtualEndpointUserSetting -Filter "displayName eq '$PolicyName'" -ErrorAction Stop | Select-Object -First 1
                if (-not $policy) {
                    throw "User settings policy '$PolicyName' not found"
                }
                $PolicyId = $policy.Id
            }
            else {
                $policy = Get-MgDeviceManagementVirtualEndpointUserSetting -CloudPcUserSettingId $PolicyId -ErrorAction Stop
            }
            
            # Get group IDs if names were provided
            if ($PSCmdlet.ParameterSetName -like '*GroupName*') {
                $GroupId = @()
                foreach ($name in $GroupName) {
                    $group = Get-MgGroup -Filter "displayName eq '$name'" -ErrorAction Stop | Select-Object -First 1
                    if (-not $group) {
                        Write-Warning "Group '$name' not found, skipping"
                        continue
                    }
                    $GroupId += $group.Id
                }
                
                if ($GroupId.Count -eq 0) {
                    throw "No valid groups found"
                }
            }
            
            if ($PSCmdlet.ShouldProcess($policy.DisplayName, "Assign to $($GroupId.Count) group(s)")) {
                # Build assignment parameters
                $assignments = @()
                foreach ($gid in $GroupId) {
                    $assignments += @{
                        Target = @{
                            '@odata.type' = '#microsoft.graph.groupAssignmentTarget'
                            GroupId = $gid
                        }
                    }
                }
                
                $assignmentParams = @{
                    Assignments = $assignments
                }
                
                # Apply assignments
                Update-MgDeviceManagementVirtualEndpointUserSetting -CloudPcUserSettingId $PolicyId -BodyParameter $assignmentParams -ErrorAction Stop
                
                Write-Information "Successfully assigned user settings policy '$($policy.DisplayName)' to $($GroupId.Count) group(s)" -InformationAction Continue
            }
        }
        catch {
            Write-Error "Failed to assign user settings policy: $($_.Exception.Message)"
            throw
        }
    }
}

<#
.SYNOPSIS
    Removes assignments from a Windows 365 user settings policy.

.DESCRIPTION
    Removes group assignments from Windows 365 user settings policies.

.PARAMETER PolicyId
    ID of the user settings policy to remove assignments from.

.PARAMETER PolicyName
    Name of the user settings policy to remove assignments from.

.PARAMETER RemoveAll
    Removes all assignments from the policy.

.EXAMPLE
    Remove-LabUserSettingsAssignment -PolicyName "Lab User Settings" -RemoveAll

.EXAMPLE
    Remove-LabUserSettingsAssignment -PolicyId "policy-guid" -RemoveAll -Force
#>
function Remove-LabUserSettingsAssignment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'ByPolicyName')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPolicyId')]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPolicyName')]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyName,
        
        [Parameter(Mandatory = $true)]
        [switch]$RemoveAll
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
    }
    
    process {
        try {
            # Get policy
            if ($PSCmdlet.ParameterSetName -eq 'ByPolicyName') {
                $policy = Get-MgDeviceManagementVirtualEndpointUserSetting -Filter "displayName eq '$PolicyName'" -ErrorAction Stop | Select-Object -First 1
                if (-not $policy) {
                    throw "User settings policy '$PolicyName' not found"
                }
                $PolicyId = $policy.Id
            }
            else {
                $policy = Get-MgDeviceManagementVirtualEndpointUserSetting -CloudPcUserSettingId $PolicyId -ErrorAction Stop
            }
            
            if ($PSCmdlet.ShouldProcess($policy.DisplayName, "Remove all assignments")) {
                $emptyAssignments = @{ Assignments = @() }
                Update-MgDeviceManagementVirtualEndpointUserSetting -CloudPcUserSettingId $PolicyId -BodyParameter $emptyAssignments -ErrorAction Stop
                
                Write-Information "Successfully removed all assignments from user settings policy: $($policy.DisplayName)" -InformationAction Continue
            }
        }
        catch {
            Write-Error "Failed to remove assignments: $($_.Exception.Message)"
            throw
        }
    }
}

#endregion Cloud PC User Settings Functions

#region Orchestration Functions

<#
.SYNOPSIS
    Creates a complete lab environment with users, groups, and policies.

.DESCRIPTION
    Orchestrates the creation of a full lab environment including users, groups, 
    a single provisioning policy, and group assignments. This function creates
    one provisioning policy that can be assigned to multiple groups (typical Windows 365 behavior).

.PARAMETER UserCount
    Number of users to create in the lab environment.

.PARAMETER UserPrefix
    Prefix for usernames. Default is "iu".

.PARAMETER CreateIndividualGroups
    Creates individual groups for each user (one user per group).

.PARAMETER CreateSharedGroup
    Creates a single shared group containing all users for policy assignment.
    This is useful when you want all users to share the same Cloud PC policy in one group.
    Cannot be used with -CreateIndividualGroups.

.PARAMETER CreateProvisioningPolicies
    Creates a single provisioning policy for the lab environment.

.PARAMETER AssignPolicies
    Assigns the provisioning policy to the created groups. Works with:
    - CreateIndividualGroups: Assigns policy to all individual groups
    - CreateSharedGroup: Assigns policy to the shared group
    - Neither: Assigns policy to the default license group

.PARAMETER OnPremisesConnectionId
    The Azure network connection ID for the provisioning policy. Required if CreateProvisioningPolicies is used.
    Use Get-MgDeviceManagementVirtualEndpointOnPremisesConnection to find available connections.

.PARAMETER RegionName
    Azure region name for automatic connection (alternative to OnPremisesConnectionId).
    Examples: "eastus", "westus2", "northeurope"

.EXAMPLE
    New-LabEnvironment -UserCount 10 -CreateIndividualGroups -CreateProvisioningPolicies -OnPremisesConnectionId "conn-id" -AssignPolicies
    Creates 10 users with individual groups and assigns policy to each group.

.EXAMPLE
    New-LabEnvironment -UserCount 50 -CreateSharedGroup -CreateProvisioningPolicies -RegionName "eastus" -AssignPolicies
    Creates 50 users, a shared group containing all users, and assigns policy to the shared group.

.EXAMPLE
    New-LabEnvironment -UserCount 5 -CreateProvisioningPolicies -RegionName "eastus" -AssignPolicies
    Creates 5 users and assigns policy to the default license group.

.OUTPUTS
    Hashtable containing created resources information.
    
.NOTES
    This function creates ONE provisioning policy for all users, which is the typical Windows 365 deployment pattern.
    Multiple users/groups share the same provisioning policy configuration.
    You MUST provide either -OnPremisesConnectionId OR -RegionName when using -CreateProvisioningPolicies.
    CreateIndividualGroups and CreateSharedGroup are mutually exclusive.
#>
function New-LabEnvironment {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 1000)]
        [int]$UserCount,
        
        [Parameter(Mandatory = $false)]
        [string]$UserPrefix = $Script:LabDefaults.UserPrefix,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateIndividualGroups,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateSharedGroup,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateProvisioningPolicies,
        
        [Parameter(Mandatory = $false)]
        [switch]$AssignPolicies,
        
        [Parameter(Mandatory = $false)]
        [string]$OnPremisesConnectionId,
        
        [Parameter(Mandatory = $false)]
        [string]$RegionName = "eastus"
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
        
        # Validate mutually exclusive parameters
        if ($CreateIndividualGroups -and $CreateSharedGroup) {
            throw "CreateIndividualGroups and CreateSharedGroup cannot be used together. Please choose one group creation method."
        }
        
        $results = @{
            Users = @()
            Groups = @()
            Policies = @()
            Success = $false
            StartTime = Get-Date
        }
    }
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess("Lab Environment with $UserCount users", "Create Complete Lab Environment")) {
                Write-Information "Starting lab environment creation..." -InformationAction Continue
                
                # Create users
                Write-Information "Creating $UserCount users..." -InformationAction Continue
                $users = New-LabUser -UserCount $UserCount -UserPrefix $UserPrefix -AddToLicenseGroup -AddToRoleGroup
                $results.Users = $users
                
                # Create individual groups if requested
                if ($CreateIndividualGroups) {
                    Write-Information "Creating individual groups for users..." -InformationAction Continue
                    foreach ($user in $users) {
                        $username = ($user.UserPrincipalName -split '@')[0]
                        $groupName = "$($Script:LabDefaults.GroupPrefix) for $username"
                        
                        try {
                            $group = New-LabGroup -GroupName $groupName
                            Add-LabUserToGroup -UserPrincipalName $user.UserPrincipalName -GroupId $group.Id
                            $results.Groups += $group
                        }
                        catch {
                            Write-Warning "Failed to create group for user $($user.UserPrincipalName): $($_.Exception.Message)"
                        }
                    }
                }
                
                # Create shared group if requested
                if ($CreateSharedGroup) {
                    Write-Information "Creating shared group for all users..." -InformationAction Continue
                    $sharedGroupName = "Lab Shared Group - $UserPrefix"
                    
                    try {
                        $sharedGroup = New-LabGroup -GroupName $sharedGroupName -Description "Shared group for $UserCount lab users"
                        $results.Groups += $sharedGroup
                        
                        Write-Information "Adding $UserCount users to shared group..." -InformationAction Continue
                        $addedCount = 0
                        foreach ($user in $users) {
                            try {
                                Add-LabUserToGroup -UserPrincipalName $user.UserPrincipalName -GroupId $sharedGroup.Id
                                $addedCount++
                            }
                            catch {
                                Write-Warning "Failed to add user $($user.UserPrincipalName) to shared group: $($_.Exception.Message)"
                            }
                        }
                        Write-Information "Added $addedCount of $UserCount users to shared group" -InformationAction Continue
                    }
                    catch {
                        Write-Warning "Failed to create shared group: $($_.Exception.Message)"
                    }
                }
                
                # Create provisioning policies if requested
                if ($CreateProvisioningPolicies) {
                    Write-Information "Creating provisioning policy..." -InformationAction Continue
                    
                    $policyName = "Lab Provisioning Policy - $UserPrefix"
                    
                    try {
                        $policyParams = @{
                            PolicyName = $policyName
                            EnableSingleSignOn = $true
                        }
                        
                        # Use Azure network connection if specified, otherwise use Microsoft-hosted with region
                        if ($OnPremisesConnectionId) {
                            $policyParams.OnPremisesConnectionId = $OnPremisesConnectionId
                            Write-Information "Using Azure network connection" -InformationAction Continue
                        }
                        else {
                            $policyParams.RegionName = $RegionName
                            Write-Information "Using Microsoft-hosted network in region: $RegionName" -InformationAction Continue
                        }
                        
                        $policy = New-LabCloudPCPolicy @policyParams
                        $results.Policies += $policy
                        
                        # Assign policy based on group creation method
                        if ($AssignPolicies -and $results.Groups.Count -gt 0) {
                            if ($CreateIndividualGroups) {
                                # Assign to all individual groups
                                Write-Information "Assigning policy to $($results.Groups.Count) individual group(s)..." -InformationAction Continue
                                
                                foreach ($group in $results.Groups) {
                                    try {
                                        Set-LabPolicyAssignment -PolicyId $policy.Id -GroupId $group.Id
                                    }
                                    catch {
                                        Write-Warning "Failed to assign policy to group $($group.DisplayName): $($_.Exception.Message)"
                                    }
                                }
                            }
                            elseif ($CreateSharedGroup) {
                                # Assign to the shared group
                                Write-Information "Assigning policy to shared group..." -InformationAction Continue
                                try {
                                    $sharedGroup = $results.Groups[0]  # Should only be one group
                                    Set-LabPolicyAssignment -PolicyId $policy.Id -GroupId $sharedGroup.Id
                                    Write-Information "Policy assigned to shared group: $($sharedGroup.DisplayName)" -InformationAction Continue
                                }
                                catch {
                                    Write-Warning "Failed to assign policy to shared group: $($_.Exception.Message)"
                                }
                            }
                        }
                        # If no groups created, assign to default license group
                        elseif ($AssignPolicies -and -not $CreateIndividualGroups -and -not $CreateSharedGroup) {
                            Write-Information "Assigning policy to default license group..." -InformationAction Continue
                            try {
                                $licenseGroup = Get-MgGroup -Filter "displayName eq '$($Script:LabDefaults.LicenseGroupName)'" -ErrorAction Stop | Select-Object -First 1
                                if ($licenseGroup) {
                                    Set-LabPolicyAssignment -PolicyId $policy.Id -GroupId $licenseGroup.Id
                                }
                                else {
                                    Write-Warning "Default license group '$($Script:LabDefaults.LicenseGroupName)' not found. Policy created but not assigned."
                                }
                            }
                            catch {
                                Write-Warning "Failed to assign policy to default license group: $($_.Exception.Message)"
                            }
                        }
                    }
                    catch {
                        Write-Warning "Failed to create provisioning policy: $($_.Exception.Message)"
                    }
                }
                
                $results.Success = $true
                $results.EndTime = Get-Date
                $results.Duration = $results.EndTime - $results.StartTime
                
                Write-Information "Lab environment creation completed successfully!" -InformationAction Continue
                Write-Information "Created: $($results.Users.Count) users, $($results.Groups.Count) groups, $($results.Policies.Count) policies" -InformationAction Continue
                Write-Information "Total time: $($results.Duration.TotalSeconds) seconds" -InformationAction Continue
            }
        }
        catch {
            $results.Success = $false
            $results.Error = $_.Exception.Message
            Write-Error "Failed to create lab environment: $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        return $results
    }
}

<#
.SYNOPSIS
    Removes a complete lab environment.

.DESCRIPTION
    Orchestrates the removal of lab resources including policies, groups, and users.

.PARAMETER UserPrefix
    Prefix to identify lab users for removal.

.PARAMETER RemovePolicies
    Removes provisioning policies matching the lab pattern.

.PARAMETER RemoveGroups
    Removes groups matching the lab pattern.

.PARAMETER RemoveUsers
    Removes users matching the prefix pattern.

.PARAMETER Force
    Bypasses all confirmation prompts.

.EXAMPLE
    Remove-LabEnvironment -UserPrefix "lu" -RemovePolicies -RemoveGroups -RemoveUsers

.OUTPUTS
    Hashtable containing removal operation results.
#>
function Remove-LabEnvironment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$UserPrefix = $Script:LabDefaults.UserPrefix,
        
        [Parameter(Mandatory = $false)]
        [switch]$RemovePolicies,
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveGroups,
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveUsers,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    begin {
        if (-not (Test-LabGraphConnection)) {
            throw "Microsoft Graph connection required. Use Connect-LabGraph first."
        }
        
        $results = @{
            PoliciesRemoved = 0
            GroupsRemoved = 0
            UsersRemoved = 0
            Success = $false
            StartTime = Get-Date
        }
    }
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess("Lab Environment", "Remove Lab Environment")) {
                Write-Information "Starting lab environment removal..." -InformationAction Continue
                
                # Remove policies first (to avoid assignment conflicts)
                if ($RemovePolicies) {
                    Write-Information "Removing provisioning policies..." -InformationAction Continue
                    $policyCountBefore = (Get-LabCloudPCPolicy -PolicyNamePattern "Lab*").Count
                    Remove-LabCloudPCPolicy -PolicyNamePattern "Lab*" -RemoveAssignments -Force:$Force
                    $policyCountAfter = (Get-LabCloudPCPolicy -PolicyNamePattern "Lab*").Count
                    $results.PoliciesRemoved = $policyCountBefore - $policyCountAfter
                }
                
                # Remove groups
                if ($RemoveGroups) {
                    Write-Information "Removing groups..." -InformationAction Continue
                    $groupCountBefore = (Get-LabGroup -GroupNamePattern "*lab group*").Count
                    Remove-LabGroup -GroupNamePattern "*lab group*" -Force:$Force
                    $groupCountAfter = (Get-LabGroup -GroupNamePattern "*lab group*").Count
                    $results.GroupsRemoved = $groupCountBefore - $groupCountAfter
                }
                
                # Remove users
                if ($RemoveUsers) {
                    Write-Information "Removing users..." -InformationAction Continue
                    $userCountBefore = (Get-LabUser -UserPrefix $UserPrefix).Count
                    Remove-LabUser -UserPrefix $UserPrefix -Force:$Force
                    $userCountAfter = (Get-LabUser -UserPrefix $UserPrefix).Count
                    $results.UsersRemoved = $userCountBefore - $userCountAfter
                }
                
                $results.Success = $true
                $results.EndTime = Get-Date
                $results.Duration = $results.EndTime - $results.StartTime
                
                Write-Information "Lab environment removal completed!" -InformationAction Continue
                Write-Information "Removed: $($results.PoliciesRemoved) policies, $($results.GroupsRemoved) groups, $($results.UsersRemoved) users" -InformationAction Continue
                Write-Information "Total time: $($results.Duration.TotalSeconds) seconds" -InformationAction Continue
            }
        }
        catch {
            $results.Success = $false
            $results.Error = $_.Exception.Message
            Write-Error "Failed to remove lab environment: $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        return $results
    }
}

#endregion Orchestration Functions

# Export module functions
Export-ModuleMember -Function @(
    # Core Environment Functions
    'Connect-LabGraph',
    'Disconnect-LabGraph', 
    'Test-LabGraphConnection',
    'New-LabUser',
    'Remove-LabUser',
    'Get-LabUser',
    'New-LabGroup',
    'Remove-LabGroup',
    'Get-LabGroup',
    'Add-LabUserToGroup',
    'Remove-LabUserFromGroup',
    'Set-LabGroupLicense',
    'Remove-LabGroupLicense',
    'Get-LabGroupLicense',
    'Get-LabAvailableLicense',
    # Windows 365 Specific Functions
    'New-LabCloudPCPolicy',
    'Remove-LabCloudPCPolicy',
    'Get-LabCloudPCPolicy',
    'Set-LabPolicyAssignment',
    'Remove-LabPolicyAssignment',
    'Get-LabCloudPC',
    'Stop-LabCloudPCGracePeriod',
    'New-LabCloudPCUserSettings',
    'Remove-LabCloudPCUserSettings',
    'Get-LabCloudPCUserSettings',
    'Set-LabUserSettingsAssignment',
    'Remove-LabUserSettingsAssignment',
    # Lab Maintenance Functions
    'New-LabEnvironment',
    'Remove-LabEnvironment',
    'Get-LabEnvironmentStatus'
)