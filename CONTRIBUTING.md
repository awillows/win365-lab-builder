# Contributing to Windows 365 Lab Builder

Thank you for your interest in contributing to the Windows 365 Lab Builder! This document provides guidelines and instructions for contributing.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project follows the Microsoft Open Source Code of Conduct. By participating, you are expected to uphold this code.

## Getting Started

1. **Fork the repository**
   ```bash
   git clone https://github.com/your-org/win365-lab-builder.git
   cd win365-lab-builder
   ```

2. **Install prerequisites**
   ```powershell
   Install-Module Microsoft.Graph.Authentication -Force
   Install-Module Microsoft.Graph.Users -Force
   Install-Module Microsoft.Graph.Groups -Force
   Install-Module Microsoft.Graph.DeviceManagement -Force
   Install-Module Pester -MinimumVersion 5.0 -Force
   Install-Module PSScriptAnalyzer -Force
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Adding New Functions

1. **Follow naming conventions**
   - Use `Verb-LabNoun` format (e.g., `New-LabUser`, `Get-LabGroup`)
   - Approved PowerShell verbs: Get, Set, New, Remove, Add, Test, Start, Stop

2. **Function template**
   ```powershell
   <#
   .SYNOPSIS
       Brief description of what the function does.
   
   .DESCRIPTION
       Detailed description of the function's purpose and behavior.
   
   .PARAMETER ParameterName
       Description of each parameter.
   
   .EXAMPLE
       Example-Command -Parameter Value
       Description of what this example does.
   
   .NOTES
       Additional information about the function.
   #>
   function Verb-LabNoun {
       [CmdletBinding(SupportsShouldProcess)]
       [OutputType([ExpectedType])]
       param(
           [Parameter(Mandatory = $true)]
           [ValidateNotNullOrEmpty()]
           [string]$RequiredParam,
           
           [Parameter(Mandatory = $false)]
           [ValidateRange(1, 100)]
           [int]$OptionalParam = 10
       )
       
       begin {
           if (-not (Test-LabGraphConnection)) {
               throw "Microsoft Graph connection required. Use Connect-LabGraph first."
           }
       }
       
       process {
           try {
               if ($PSCmdlet.ShouldProcess($RequiredParam, "Action Description")) {
                   # Implementation
                   Write-Information "Operation completed" -InformationAction Continue
               }
           }
           catch {
               Write-Error "Operation failed: $($_.Exception.Message)"
               throw
           }
       }
       
       end {
           # Cleanup if needed
       }
   }
   ```

3. **Add to module manifest**
   - Update `FunctionsToExport` in `W365LabBuilder.psd1`
   - Update `Export-ModuleMember` at end of `.psm1`

## Coding Standards

### PowerShell Best Practices

1. **Use approved verbs**
   ```powershell
   Get-Verb | Where-Object { $_.Group -eq 'Common' }
   ```

2. **Parameter validation**
   ```powershell
   [ValidateNotNullOrEmpty()]
   [ValidateRange(1, 1000)]
   [ValidateSet('Value1', 'Value2')]
   [ValidateScript({ Test-Path $_ })]
   ```

3. **Error handling**
   ```powershell
   try {
       # Code that might fail
   }
   catch {
       Write-Error "Descriptive error message: $($_.Exception.Message)"
       throw
   }
   ```

4. **Support WhatIf/Confirm for destructive operations**
   ```powershell
   [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
   ```

5. **Output types**
   ```powershell
   [OutputType([Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser])]
   ```

### Code Style

- **Indentation**: 4 spaces (no tabs)
- **Line length**: Maximum 120 characters
- **Braces**: Opening brace on same line
- **Variables**: Use `$PascalCase` for function parameters, `$camelCase` for local variables
- **Comments**: Use inline comments sparingly, prefer descriptive function/parameter names

### PSScriptAnalyzer

All code must pass PSScriptAnalyzer with default rules:

```powershell
Invoke-ScriptAnalyzer -Path ./W365LabBuilder -Recurse -Settings PSGallery
```

## Testing Requirements

### Writing Tests

1. **Create test file** in `W365LabBuilder/Tests/`
   ```powershell
   # FunctionName.Tests.ps1
   Describe "Function Name Tests" {
       Context "Parameter Validation" {
           It "Should throw on invalid input" {
               { Function-Name -Invalid } | Should -Throw
           }
       }
       
       Context "Functionality" {
           It "Should return expected result" {
               $result = Function-Name -Valid
               $result | Should -Not -BeNullOrEmpty
           }
       }
   }
   ```

2. **Run tests locally**
   ```powershell
   Invoke-Pester -Path ./W365LabBuilder/Tests
   ```

3. **Test coverage**: Aim for >80% code coverage

### Required Tests

- ✅ Parameter validation
- ✅ Error handling
- ✅ Expected output
- ✅ Edge cases
- ✅ Integration tests (where applicable)

## Documentation

### Required Documentation

1. **Comment-based help** for all functions
   - `.SYNOPSIS`
   - `.DESCRIPTION`
   - `.PARAMETER` (for each parameter)
   - `.EXAMPLE` (at least 2 examples)
   - `.NOTES` (optional)

2. **Update README.md** if adding new features

3. **Update MIGRATION.md** if changing function signatures

4. **Add examples** in `Examples/` folder for major features

### Documentation Standards

- Clear, concise language
- Real-world examples
- Explain parameters and outputs
- Include error handling examples
- Note prerequisites and permissions

## Pull Request Process

### Before Submitting

1. ✅ All tests pass locally
2. ✅ PSScriptAnalyzer shows no errors
3. ✅ Documentation is complete
4. ✅ Examples are provided
5. ✅ Code follows style guidelines
6. ✅ Commit messages are clear

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing
- [ ] Unit tests added/updated
- [ ] All tests pass
- [ ] Manual testing completed

## Documentation
- [ ] Function help added/updated
- [ ] README updated (if needed)
- [ ] Examples added (if needed)

## Checklist
- [ ] Code follows style guidelines
- [ ] PSScriptAnalyzer passes
- [ ] No breaking changes (or documented)
- [ ] Backward compatible (or version bumped)
```

### Review Process

1. Code review by maintainers
2. Manual testing and validation
3. Address feedback
4. Approval required before merge
5. Squash and merge to main branch

## Reporting Issues

### Bug Reports

Include:
- PowerShell version (`$PSVersionTable`)
- Module version
- Steps to reproduce
- Expected vs actual behavior
- Error messages (full stack trace)
- Minimal code example

### Feature Requests

Include:
- Clear description of the feature
- Use case / business value
- Proposed API / function signature
- Example usage
- Potential impacts

## Version Bumping

Follow Semantic Versioning (SemVer):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

Update version in:
- `W365LabBuilder.psd1` (ModuleVersion)
- `README.md` (Version History)

## Getting Help

- **Documentation**: Check README.md and function help
- **Examples**: Review Examples/ folder
- **Issues**: Search existing issues
- **Discussions**: Use GitHub Discussions for questions

## Recognition

Contributors will be acknowledged in:
- Release notes
- README.md contributors section
- Git commit history

Thank you for contributing to the Windows 365 Lab Builder! 🎉