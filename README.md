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

`Get-DevContext` is the single immutable snapshot of the current developer environment. It exposes independent `PowerShell`, `Git`, `Azure`, `DotNet`, `Docker`, `Kubernetes`, `AI`, and `Machine` provider objects. Providers isolate failures and own their cache lifetime and refresh policy.

```powershell
$context = Get-DevContext
$context.Git.Branch
$context.DotNet.Sdks
$context.Azure.Subscription
Show-DevContext
```

Every provider includes `Healthy`, `ElapsedMilliseconds`, `Cached`, `LastRefreshUtc`, cache age, and cache-hit metadata. Use `Get-DevContext -Refresh` to force all providers to refresh. External commands are confined to provider files under `src/Aundy.DevShell/Context`; providers never call one another.
