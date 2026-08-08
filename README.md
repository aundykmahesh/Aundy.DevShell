# Aundy.DevShell

A reusable PowerShell 7.6+ developer toolkit for Azure, .NET, DevOps, Git, and local AI workflows.

Start with [Getting Started](GETTING_STARTED.md). For internals and extension points, see [Architecture](ARCHITECTURE.md).

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

Supported styles are `Minimal`, `Developer`, `Cloud`, `AI`, and `Presentation`. `Classic` and `Compact` remain compatibility layouts. The generated `themes/Aundy.omp.json` is an implementation artifact; change prompt settings or builders instead of editing that file.

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

## Developer Workflow Engine

List, plan, invoke, and diagnose registered developer workflows with `Get-DevWorkflow`, `Resolve-DevWorkflow`, `Invoke-DevWorkflow`, and `Test-DevWorkflow`. See [Developer Workflow Engine](docs/Workflow-Engine.md) for contracts, security boundaries, cache behavior, and examples.

## Configured navigation

Use `Get-DevLocation` to list explicitly configured source locations and `Set-DevLocation CBI` to navigate safely. Locations use portable environment-expanded roots and parent-relative children without filesystem scanning. See [Configured workspace navigation](docs/Workspace-Navigation.md).
# Prompt Engine v2

The data-driven prompt consumes only `Get-DevContext`, supports five declarative styles, and generates the Oh My Posh theme. See [Prompt Engine development](docs/Prompt-Engine.md).
