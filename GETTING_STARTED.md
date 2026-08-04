# Getting Started

## Requirements

- Windows with PowerShell 7.6 or later
- Git
- Oh My Posh
- Optional: Azure CLI or Az PowerShell, .NET SDK, Docker, kubectl, and Ollama

Optional tools must be available on `PATH` for their Context Engine providers to detect them.

## Install

Clone the repository:

```powershell
git clone https://github.com/aundykmahesh/Aundy.DevShell.git C:\Git\Aundy.DevShell
```

Copy the module into a PowerShell module path:

```powershell
$moduleRoot = ($env:PSModulePath -split ';')[0]
$destination = Join-Path $moduleRoot 'Aundy.DevShell'
New-Item $destination -ItemType Directory -Force | Out-Null
Copy-Item C:\Git\Aundy.DevShell\src\Aundy.DevShell\* $destination -Recurse -Force
```

Back up the current profile, review the supplied bootstrapper, and install it:

```powershell
if (Test-Path $PROFILE) { Copy-Item $PROFILE "$PROFILE.backup" }
Copy-Item C:\Git\Aundy.DevShell\profile\Microsoft.PowerShell_profile.ps1 $PROFILE -Force
```

Open a new PowerShell session.

## Verify

```powershell
Get-Module Aundy.DevShell
Show-DevContext
Show-DevShellPrompt
Show-DevShellDiagnostics
```

## Choose a prompt style

```powershell
Set-DevShellPromptStyle Minimal
Set-DevShellPromptStyle Developer
Set-DevShellPromptStyle Cloud
Set-DevShellPromptStyle AI
Set-DevShellPromptStyle Presentation
```

The selected style applies immediately to the current session. Set `Prompt.Style` in `$destination\Settings.psd1` to choose the startup default for an installed module.

## Development workflow

Import directly from a clone and run tests:

```powershell
Import-Module C:\Git\Aundy.DevShell\src\Aundy.DevShell\Aundy.DevShell.psd1 -Force
Invoke-Pester C:\Git\Aundy.DevShell\tests
```

After changing module code or settings, run:

```powershell
Reload-Profile
```

See [ARCHITECTURE.md](ARCHITECTURE.md) and [Prompt Engine development](docs/Prompt-Engine.md) for implementation details.
