# Windows 365 Lab Builder Configuration File
# Copy this file to config.psd1 and customize for your environment

@{
    # User Configuration
    UserDefaults = @{
        Prefix = "lu"                      # Default username prefix
        Password = "Lab2024!!"             # Default password for new users
        UsageLocation = "US"               # Default usage location
        StartNumber = 1                    # Default starting number
        Domain = ""                        # Leave empty for auto-detection
    }

    # Group Configuration
    GroupDefaults = @{
        Prefix = "Lab Group"               # Default group name prefix
        LicenseGroupName = "LabLicenseGroup"
        RoleGroupName = "LabRoleGroup"
    }

    # Cloud PC Configuration
    CloudPCDefaults = @{
        Region = "eastus"                  # Default region (Azure region format)
        RegionGroup = "eastus"             # Default region group
        TimeZone = "Pacific Standard Time" # Default time zone
        Language = "en-US"                 # Default language
        ImageId = "microsoftwindowsdesktop_windows-ent-cpc_win11-24H2-ent-cpc-m365"
        ImageDisplay = "Windows 11 Enterprise + Microsoft 365 Apps 24H2"
        EnableSingleSignOn = $true         # Enable SSO by default
    }

    # Connection Configuration
    Connection = @{
        TenantId = ""                      # Default tenant ID (leave empty for prompt)
        Scopes = @(                        # Required Graph API scopes
            "User.ReadWrite.All"
            "Directory.AccessAsUser.All"
            "Directory.ReadWrite.All"
            "Application.ReadWrite.All"
            "DeviceManagementServiceConfig.ReadWrite.All"
            "CloudPC.ReadWrite.All"
            "DeviceManagementVirtualEndpoint.ReadWrite.All"
        )
    }

    # Operational Limits
    Limits = @{
        MaxUsers = 1000                    # Maximum users in single operation
        MaxBatchSize = 50                  # Batch size for bulk operations
        ThrottleDelay = 500               # Milliseconds delay between operations
        RetryAttempts = 3                  # Number of retry attempts on failure
    }

    # Logging Configuration
    Logging = @{
        Enabled = $true                    # Enable logging
        LogPath = ".\Logs"                 # Log file path
        LogLevel = "Information"           # Verbose, Information, Warning, Error
        RetentionDays = 30                 # Keep logs for 30 days
    }

    # Feature Flags
    Features = @{
        AutoCleanupOnFailure = $true       # Auto-cleanup partial resources on failure
        ProgressBar = $true                # Show progress bars
        ColorOutput = $true                # Use colored console output
        ConfirmByDefault = $true           # Require confirmation for destructive ops
    }
}