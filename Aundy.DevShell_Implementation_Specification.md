# Aundy.DevShell - Implementation Specification v1.0

## Overview

You are implementing a production-quality PowerShell developer toolkit
called **Aundy.DevShell**.

This project is **not** a PowerShell profile. The PowerShell profile is
only a bootstrapper.

The actual implementation must be a proper PowerShell module following
Microsoft's module guidelines.

## Repository

-   GitHub: https://github.com/aundykmahesh/Aundy.DevShell
-   Target: PowerShell 7.6+
-   Platform: Windows 11 (future cross-platform)

## Objectives

Create a reusable developer toolkit for:

-   Azure Engineers
-   .NET Developers
-   DevOps Engineers
-   Local AI Developers
-   Git power users

## Design Principles

1.  Profile must contain less than 100 lines.
2.  Everything else belongs inside modules.
3.  No global variables.
4.  No hardcoded paths.
5.  Everything configurable.
6.  Approved PowerShell verbs only.
7.  Future cross-platform compatibility.
8.  No breaking changes between versions.

## Repository Structure

``` text
Aundy.DevShell
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── release.yml
│       └── analyze.yml
├── docs/
├── installer/
│   ├── Install.ps1
│   └── Uninstall.ps1
├── profile/
│   └── Microsoft.PowerShell_profile.ps1
├── src/
│   └── Aundy.DevShell/
│       ├── Aundy.DevShell.psd1
│       ├── Aundy.DevShell.psm1
│       ├── Public/
│       └── Private/
├── tests/
├── themes/
├── LICENSE
├── README.md
├── CHANGELOG.md
├── .editorconfig
├── .gitignore
└── PSScriptAnalyzerSettings.psd1
```

## Module Layout

``` text
Public/
    Get-OllamaStatus.ps1
    Open-AIAundy.ps1
    Connect-BoqAzure.ps1

Private/
    Get-Settings.ps1
    Test-IsAdministrator.ps1
    Write-DevShellLog.ps1
```

The root module must dot-source all scripts and export only public
functions.

## Module Manifest

Include:

-   RequiredModules
-   CompatiblePSEditions
-   PowerShellVersion
-   FunctionsToExport
-   AliasesToExport
-   Tags
-   LicenseUri
-   ProjectUri

## Profile Responsibilities

Only:

1.  Load settings
2.  Import module
3.  Initialize prompt
4.  Configure PSReadLine
5.  Display welcome banner

## Prompt Theme

Create `themes/Aundy.omp.json`.

Display:

-   Time
-   Azure Subscription
-   Git Branch
-   Git Dirty Status
-   Current Folder
-   .NET SDK Version
-   Docker Status
-   Ollama Status
-   Execution Time
-   Prompt Character

## Configuration

Create `Settings.psd1`.

Support:

-   Repository root
-   AI URLs
-   Ollama endpoint
-   OpenWebUI endpoint
-   AI.Aundy URL
-   Prompt settings
-   Preferred editor
-   Git defaults

## Logging

Implement:

-   Write-DevShellVerbose
-   Write-DevShellInformation
-   Write-DevShellWarning
-   Write-DevShellError

Support transcript logging.

## Modules

Implement:

-   Core
-   Prompt
-   Git
-   Azure
-   Docker
-   Ollama
-   Claude
-   AI.Aundy
-   Utilities

## Git Module

Functions:

-   Get-GitStatus
-   Get-GitBranch
-   Update-GitRepository
-   Invoke-GitGraph
-   Clear-GitWorkspace

Aliases:

-   gs
-   gg
-   gp
-   gpush
-   gb

## Azure Module

Functions:

-   Connect-BoqAzure
-   Get-BoqSubscription
-   Get-BoqResourceGroup
-   Get-BoqKeyVault
-   Get-BoqStorageAccount

## Ollama Module

Functions:

-   Get-OllamaModels
-   Get-OllamaStatus
-   Test-Ollama
-   Restart-Ollama

## AI.Aundy Module

Functions:

-   Open-AIAundy
-   Test-AIAundyHealth
-   Get-AIAundyStatus

Health checks:

-   Cloudflare Tunnel
-   Ollama
-   Open WebUI
-   Windows Services
-   HTTP endpoints

## Docker Module

Functions:

-   Get-DockerStatus
-   Restart-Docker
-   Get-DockerContainers

## Utilities

Functions:

-   Update-DevShell
-   Reload-Profile
-   Open-Repository
-   Open-CurrentDirectory
-   Test-Administrator

## Installer

Install.ps1 must:

-   Install Oh My Posh
-   Install Terminal Icons
-   Install Nerd Font
-   Install PSReadLine
-   Copy profile
-   Copy themes
-   Import module
-   Verify installation

## Testing

-   Pester
-   Module import validation
-   Smoke tests

## Static Analysis

-   PSScriptAnalyzer
-   Zero warnings

## CI

GitHub Actions:

-   PSScriptAnalyzer
-   Pester
-   Build module
-   Validate manifest

## Documentation

Every public function must include:

-   Comment-based help
-   Examples
-   Parameters
-   Output
-   Notes

## Coding Standards

-   PowerShell 7.6
-   Set-StrictMode -Version Latest
-   CmdletBinding()
-   SupportsShouldProcess where appropriate
-   Terminating exceptions
-   Approved verbs only
-   No Write-Host inside modules
-   No global state
-   No duplicated code

## Suggested Commits

``` text
feat: scaffold module foundation
feat: add custom prompt
feat: implement Git module
feat: implement Azure module
feat: implement Docker module
feat: implement Ollama module
feat: implement AI.Aundy module
feat: add installer
feat: add tests
feat: add CI pipeline
docs: complete documentation
```

## Final Goal

Produce a professional-grade PowerShell developer platform suitable for
open-source publication. The PowerShell profile should remain a
lightweight bootstrapper while all functionality resides in a modular,
tested, maintainable PowerShell module.
