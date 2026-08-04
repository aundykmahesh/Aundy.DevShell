# Aundy.DevShell

A reusable PowerShell 7.6+ developer toolkit for Azure, .NET, DevOps, Git, and local AI workflows.

## Development

```powershell
Import-Module ./src/Aundy.DevShell/Aundy.DevShell.psd1 -Force
Get-DevShellSettings
Invoke-Pester ./tests
```

The checked-in profile is intentionally a lightweight bootstrapper. Product functionality belongs in the module under `src/Aundy.DevShell`.

## Prompt engine

Prompt behavior is configured in `src/Aundy.DevShell/Settings.psd1`. The engine builds a backend-neutral prompt model before generating the Oh My Posh theme:

```powershell
Get-DevShellPrompt
Set-DevShellPromptStyle -Style Compact
New-DevShellPromptTheme
```

Supported layouts are `Classic`, `Compact`, and `Minimal`. The generated `themes/Aundy.omp.json` is an implementation artifact; change prompt settings or builders instead of editing that file.

Use `Reload-Profile` after changing module code or settings. It reloads the module, regenerates the theme, reinitializes Oh My Posh, and reports elapsed time. Run `Show-DevShellDiagnostics` explicitly to inspect PowerShell, renderer, theme, startup, Azure, Git, settings, and style status; startup itself remains silent.

## Context engine

`Get-DevContext` is the single read-only snapshot of the current developer environment. Its independent Git, Azure, Docker/kubectl, .NET, and PowerShell providers isolate failures and cache data using provider-specific lifetimes. Callers do not need to manage the cache.

```powershell
$context = Get-DevContext
$context.GitBranch
Show-DevContext
```

External commands are confined to files under `src/Aundy.DevShell/Context`. Add a provider by adding one provider file and one entry to `$script:DevContextProviders` in `Get-DevContext.ps1`.
