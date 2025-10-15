<#
.SYNOPSIS
    Build and test script for the Windows 365 Lab Builder Module

.DESCRIPTION
    This script performs various build tasks including testing, validation,
    and packaging of the Windows 365 Lab Builder Module.

.PARAMETER Task
    The build task to execute. Valid values: Test, Analyze, Build, Package, All

.EXAMPLE
    .\build.ps1 -Task Test
    Runs all Pester tests

.EXAMPLE
    .\build.ps1 -Task All
    Runs all build tasks
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Test', 'Analyze', 'Build', 'Package', 'All', 'Clean')]
    [string]$Task = 'All'
)

$ErrorActionPreference = 'Stop'

# Module variables
$ModuleName = 'W365LabBuilder'
$ModulePath = Join-Path $PSScriptRoot $ModuleName
$OutputPath = Join-Path $PSScriptRoot 'Output'
$TestsPath = Join-Path $ModulePath 'Tests'

# Helper functions
function Write-TaskHeader {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Install-Dependencies {
    Write-TaskHeader "Installing Dependencies"
    
    $requiredModules = @(
        @{ Name = 'Pester'; MinimumVersion = '5.0.0' }
        @{ Name = 'PSScriptAnalyzer'; MinimumVersion = '1.20.0' }
    )
    
    foreach ($module in $requiredModules) {
        $installed = Get-Module -Name $module.Name -ListAvailable | 
            Where-Object { $_.Version -ge [version]$module.MinimumVersion }
            
        if (-not $installed) {
            Write-Host "Installing $($module.Name)..." -ForegroundColor Yellow
            Install-Module -Name $module.Name -MinimumVersion $module.MinimumVersion -Force -Scope CurrentUser
            Write-Host "✓ Installed $($module.Name)" -ForegroundColor Green
        } else {
            Write-Host "✓ $($module.Name) already installed" -ForegroundColor Green
        }
    }
}

function Invoke-Tests {
    Write-TaskHeader "Running Pester Tests"
    
    if (-not (Test-Path $TestsPath)) {
        Write-Warning "No tests found at $TestsPath"
        return
    }
    
    $config = New-PesterConfiguration
    $config.Run.Path = $TestsPath
    $config.Output.Verbosity = 'Detailed'
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = Join-Path $ModulePath "$ModuleName.psm1"
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = Join-Path $OutputPath 'testResults.xml'
    
    $result = Invoke-Pester -Configuration $config
    
    if ($result.FailedCount -gt 0) {
        throw "Tests failed: $($result.FailedCount) test(s) failed"
    }
    
    Write-Host "`n✓ All tests passed!" -ForegroundColor Green
    Write-Host "Code Coverage: $([math]::Round($result.CodeCoverage.CoveragePercent, 2))%" -ForegroundColor Cyan
}

function Invoke-Analyze {
    Write-TaskHeader "Running PSScriptAnalyzer"
    
    $results = Invoke-ScriptAnalyzer -Path $ModulePath -Recurse -Settings PSGallery
    
    if ($results) {
        Write-Host "PSScriptAnalyzer found issues:`n" -ForegroundColor Yellow
        $results | Format-Table -AutoSize
        
        $errors = $results | Where-Object Severity -eq 'Error'
        $warnings = $results | Where-Object Severity -eq 'Warning'
        
        Write-Host "`nSummary:" -ForegroundColor Cyan
        Write-Host "  Errors: $($errors.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { 'Red' } else { 'Green' })
        Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -gt 0) { 'Yellow' } else { 'Green' })
        
        if ($errors.Count -gt 0) {
            throw "PSScriptAnalyzer found $($errors.Count) error(s)"
        }
        
        if ($warnings.Count -gt 0) {
            Write-Warning "PSScriptAnalyzer found $($warnings.Count) warning(s)"
        }
    } else {
        Write-Host "✓ No issues found by PSScriptAnalyzer" -ForegroundColor Green
    }
}

function Invoke-Build {
    Write-TaskHeader "Building Module"
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Validate module manifest
    Write-Host "Validating module manifest..." -ForegroundColor Yellow
    $manifestPath = Join-Path $ModulePath "$ModuleName.psd1"
    
    try {
        $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
        Write-Host "✓ Module manifest is valid" -ForegroundColor Green
        Write-Host "  Module: $($manifest.Name)" -ForegroundColor White
        Write-Host "  Version: $($manifest.Version)" -ForegroundColor White
        Write-Host "  Functions: $($manifest.ExportedFunctions.Count)" -ForegroundColor White
    }
    catch {
        throw "Module manifest validation failed: $($_.Exception.Message)"
    }
    
    # Import module to validate
    Write-Host "`nImporting module for validation..." -ForegroundColor Yellow
    try {
        Import-Module $manifestPath -Force -ErrorAction Stop
        $module = Get-Module -Name $ModuleName
        Write-Host "✓ Module imported successfully" -ForegroundColor Green
        Write-Host "  Exported Functions: $($module.ExportedFunctions.Count)" -ForegroundColor White
        
        # Validate help for all functions
        Write-Host "`nValidating function help..." -ForegroundColor Yellow
        $functionsWithoutHelp = @()
        
        foreach ($function in $module.ExportedFunctions.Keys) {
            $help = Get-Help $function
            if (-not $help.Synopsis -or $help.Synopsis -like "*$function*") {
                $functionsWithoutHelp += $function
            }
        }
        
        if ($functionsWithoutHelp.Count -gt 0) {
            Write-Warning "Functions without proper help: $($functionsWithoutHelp -join ', ')"
        } else {
            Write-Host "✓ All functions have proper help documentation" -ForegroundColor Green
        }
        
        Remove-Module $ModuleName -Force
    }
    catch {
        throw "Module import validation failed: $($_.Exception.Message)"
    }
}

function Invoke-Package {
    Write-TaskHeader "Packaging Module"
    
    $version = (Import-PowerShellDataFile (Join-Path $ModulePath "$ModuleName.psd1")).ModuleVersion
    $packagePath = Join-Path $OutputPath "$ModuleName-v$version.zip"
    
    # Remove existing package
    if (Test-Path $packagePath) {
        Remove-Item $packagePath -Force
    }
    
    # Create package
    Write-Host "Creating package: $packagePath" -ForegroundColor Yellow
    Compress-Archive -Path $ModulePath -DestinationPath $packagePath -Force
    
    $size = [math]::Round((Get-Item $packagePath).Length / 1KB, 2)
    Write-Host "✓ Package created successfully" -ForegroundColor Green
    Write-Host "  Location: $packagePath" -ForegroundColor White
    Write-Host "  Size: $size KB" -ForegroundColor White
}

function Invoke-Clean {
    Write-TaskHeader "Cleaning Build Artifacts"
    
    if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Recurse -Force
        Write-Host "✓ Cleaned output directory" -ForegroundColor Green
    }
    
    # Clean test results
    $testResults = Join-Path $PSScriptRoot 'testResults.xml'
    if (Test-Path $testResults) {
        Remove-Item $testResults -Force
        Write-Host "✓ Cleaned test results" -ForegroundColor Green
    }
    
    Write-Host "`n✓ Clean complete" -ForegroundColor Green
}

# Main execution
try {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Windows 365 Lab Builder Build Script ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Install dependencies
    Install-Dependencies
    
    # Execute requested task
    switch ($Task) {
        'Test' {
            Invoke-Tests
        }
        'Analyze' {
            Invoke-Analyze
        }
        'Build' {
            Invoke-Build
        }
        'Package' {
            Invoke-Build
            Invoke-Package
        }
        'Clean' {
            Invoke-Clean
        }
        'All' {
            Invoke-Analyze
            Invoke-Build
            Invoke-Tests
            Invoke-Package
        }
    }
    
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║         Build Completed Successfully   ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Green
}
catch {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║            Build Failed!               ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Red
    Write-Error $_.Exception.Message
    exit 1
}