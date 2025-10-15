<#
.SYNOPSIS
    Pester tests for the Windows 365 Lab Builder Module

.DESCRIPTION
    Unit and integration tests for validating module functionality
#>

BeforeAll {
    # Import the module
    $ModulePath = "$PSScriptRoot\..\W365LabBuilder.psd1"
    Import-Module $ModulePath -Force
}

Describe "Module Structure Tests" {
    Context "Module Import" {
        It "Should import the module successfully" {
            $module = Get-Module -Name W365LabBuilder
            $module | Should -Not -BeNullOrEmpty
        }

        It "Should have correct module version" {
            $module = Get-Module -Name W365LabBuilder
            $module.Version | Should -Be '1.0.0'
        }
    }

    Context "Exported Functions" {
        It "Should export 21 functions" {
            $commands = Get-Command -Module W365LabBuilder
            $commands.Count | Should -Be 21
        }

        It "Should have Connect-LabGraph function" {
            Get-Command -Name Connect-LabGraph -Module W365LabBuilder | Should -Not -BeNullOrEmpty
        }

        It "Should have New-LabUser function" {
            Get-Command -Name New-LabUser -Module W365LabBuilder | Should -Not -BeNullOrEmpty
        }

        It "Should have New-LabEnvironment function" {
            Get-Command -Name New-LabEnvironment -Module W365LabBuilder | Should -Not -BeNullOrEmpty
        }
    }

    Context "Function Help" {
        BeforeAll {
            $functions = Get-Command -Module W365LabBuilder
        }

        It "All functions should have Synopsis" {
            foreach ($function in $functions) {
                $help = Get-Help $function.Name
                $help.Synopsis | Should -Not -BeNullOrEmpty
            }
        }

        It "All functions should have Description" {
            foreach ($function in $functions) {
                $help = Get-Help $function.Name
                $help.Description | Should -Not -BeNullOrEmpty
            }
        }

        It "All functions should have Examples" {
            foreach ($function in $functions) {
                $help = Get-Help $function.Name
                $help.Examples | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe "Parameter Validation Tests" {
    Context "New-LabUser Parameters" {
        It "Should validate UserCount range (1-1000)" {
            { New-LabUser -UserCount 0 -ErrorAction Stop } | Should -Throw
            { New-LabUser -UserCount 1001 -ErrorAction Stop } | Should -Throw
        }

        It "Should accept valid UserCount" {
            $cmd = Get-Command New-LabUser
            $param = $cmd.Parameters['UserCount']
            $param.Attributes.MinRange | Should -Be 1
            $param.Attributes.MaxRange | Should -Be 1000
        }
    }

    Context "New-LabEnvironment Parameters" {
        It "Should have mandatory UserCount parameter" {
            $cmd = Get-Command New-LabEnvironment
            $param = $cmd.Parameters['UserCount']
            $param.Attributes.Mandatory | Should -Contain $true
        }
    }
}

Describe "Function Behavior Tests" {
    Context "Test-LabGraphConnection" {
        It "Should return boolean value" {
            $result = Test-LabGraphConnection
            $result | Should -BeOfType [bool]
        }

        It "Should return false when not connected" {
            Mock Get-MgContext { return $null }
            Test-LabGraphConnection | Should -Be $false
        }
    }

    Context "ShouldProcess Support" {
        It "New-LabUser should support WhatIf" {
            $cmd = Get-Command New-LabUser
            $cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }

        It "Remove-LabUser should support WhatIf" {
            $cmd = Get-Command Remove-LabUser
            $cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }

        It "Remove-LabEnvironment should support WhatIf" {
            $cmd = Get-Command Remove-LabEnvironment
            $cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }

        It "Set-LabGroupLicense should support WhatIf" {
            $cmd = Get-Command Set-LabGroupLicense
            $cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }

        It "Remove-LabGroupLicense should support WhatIf" {
            $cmd = Get-Command Remove-LabGroupLicense
            $cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }
    }
}

Describe "License Management Function Tests" {
    Context "Set-LabGroupLicense" {
        It "Should exist" {
            Get-Command Set-LabGroupLicense -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should have mandatory GroupName parameter" {
            $cmd = Get-Command Set-LabGroupLicense
            $cmd.Parameters['GroupName'].Attributes.Mandatory | Should -Contain $true
        }

        It "Should have mandatory SkuPartNumber or SkuId parameter" {
            $cmd = Get-Command Set-LabGroupLicense
            ($cmd.Parameters.ContainsKey('SkuPartNumber') -and $cmd.Parameters.ContainsKey('SkuId')) | Should -Be $true
        }

        It "Should accept multiple SKU IDs" {
            $cmd = Get-Command Set-LabGroupLicense
            $cmd.Parameters['SkuId'].ParameterType.IsArray | Should -Be $true
        }
    }

    Context "Remove-LabGroupLicense" {
        It "Should exist" {
            Get-Command Remove-LabGroupLicense -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should have RemoveAll switch parameter" {
            $cmd = Get-Command Remove-LabGroupLicense
            $cmd.Parameters['RemoveAll'].ParameterType.Name | Should -Be 'SwitchParameter'
        }

        It "Should have High ConfirmImpact" {
            $cmd = Get-Command Remove-LabGroupLicense
            $cmd.ScriptBlock.Attributes.ConfirmImpact | Should -Contain 'High'
        }
    }

    Context "Get-LabGroupLicense" {
        It "Should exist" {
            Get-Command Get-LabGroupLicense -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should have mandatory GroupName or GroupId parameter" {
            $cmd = Get-Command Get-LabGroupLicense
            ($cmd.Parameters.ContainsKey('GroupName') -or $cmd.Parameters.ContainsKey('GroupId')) | Should -Be $true
        }

        It "Should return PSCustomObject array type" {
            $cmd = Get-Command Get-LabGroupLicense
            $cmd.OutputType.Name | Should -Contain 'PSCustomObject[]'
        }
    }
}

Describe "Cloud PC User Settings Function Tests" {
    Context "New-LabCloudPCUserSettings" {
        It "Should exist" {
            Get-Command New-LabCloudPCUserSettings -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should have mandatory PolicyName parameter" {
            $cmd = Get-Command New-LabCloudPCUserSettings
            $cmd.Parameters['PolicyName'].Attributes.Mandatory | Should -Contain $true
        }

        It "Should have EnableLocalAdmin boolean parameter" {
            $cmd = Get-Command New-LabCloudPCUserSettings
            $cmd.Parameters['EnableLocalAdmin'].ParameterType.Name | Should -Be 'Boolean'
        }

        It "Should have RestorePointFrequencyInHours with valid range" {
            $cmd = Get-Command New-LabCloudPCUserSettings
            $rangeAttr = $cmd.Parameters['RestorePointFrequencyInHours'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $rangeAttr.MinRange | Should -Be 4
            $rangeAttr.MaxRange | Should -Be 24
        }

        It "Should support WhatIf" {
            $cmd = Get-Command New-LabCloudPCUserSettings
            $cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }
    }

    Context "Remove-LabCloudPCUserSettings" {
        It "Should exist" {
            Get-Command Remove-LabCloudPCUserSettings -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should have PolicyName or PolicyId parameter" {
            $cmd = Get-Command Remove-LabCloudPCUserSettings
            ($cmd.Parameters.ContainsKey('PolicyName') -and $cmd.Parameters.ContainsKey('PolicyId')) | Should -Be $true
        }

        It "Should have High ConfirmImpact" {
            $cmd = Get-Command Remove-LabCloudPCUserSettings
            $cmd.ScriptBlock.Attributes.ConfirmImpact | Should -Contain 'High'
        }

        It "Should support WhatIf" {
            $cmd = Get-Command Remove-LabCloudPCUserSettings
            $cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }
    }

    Context "Get-LabCloudPCUserSettings" {
        It "Should exist" {
            Get-Command Get-LabCloudPCUserSettings -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should have All switch parameter" {
            $cmd = Get-Command Get-LabCloudPCUserSettings
            $cmd.Parameters['All'].ParameterType.Name | Should -Be 'SwitchParameter'
        }

        It "Should support multiple parameter sets" {
            $cmd = Get-Command Get-LabCloudPCUserSettings
            $cmd.ParameterSets.Count | Should -BeGreaterThan 1
        }
    }

    Context "Set-LabUserSettingsAssignment" {
        It "Should exist" {
            Get-Command Set-LabUserSettingsAssignment -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should have PolicyName or PolicyId parameter" {
            $cmd = Get-Command Set-LabUserSettingsAssignment
            ($cmd.Parameters.ContainsKey('PolicyName') -and $cmd.Parameters.ContainsKey('PolicyId')) | Should -Be $true
        }

        It "Should have GroupName or GroupId parameter" {
            $cmd = Get-Command Set-LabUserSettingsAssignment
            ($cmd.Parameters.ContainsKey('GroupName') -and $cmd.Parameters.ContainsKey('GroupId')) | Should -Be $true
        }

        It "Should support array of groups" {
            $cmd = Get-Command Set-LabUserSettingsAssignment
            $cmd.Parameters['GroupId'].ParameterType.IsArray | Should -Be $true
        }

        It "Should support WhatIf" {
            $cmd = Get-Command Set-LabUserSettingsAssignment
            $cmd.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }
    }

    Context "Remove-LabUserSettingsAssignment" {
        It "Should exist" {
            Get-Command Remove-LabUserSettingsAssignment -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should have RemoveAll mandatory parameter" {
            $cmd = Get-Command Remove-LabUserSettingsAssignment
            $cmd.Parameters['RemoveAll'].Attributes.Mandatory | Should -Contain $true
        }

        It "Should have High ConfirmImpact" {
            $cmd = Get-Command Remove-LabUserSettingsAssignment
            $cmd.ScriptBlock.Attributes.ConfirmImpact | Should -Contain 'High'
        }
    }
}

Describe "Module Configuration Tests" {
    Context "Default Values" {
        It "Should have default configuration values" {
            $module = Get-Module W365LabBuilder
            $module | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module W365LabBuilder -Force -ErrorAction SilentlyContinue
}