# Prompt Engine v2

## Architecture and lifecycle

The profile calls `Get-DevContext`, then passes that immutable snapshot to `Get-DevShellPrompt`. The Prompt Engine evaluates registered segments and produces a backend-neutral `PromptModel` with `Left`, `Right`, `Transient`, and `Secondary` collections. `Build-Theme` is the isolated Oh My Posh renderer; it converts visible model entries to generated JSON without knowing about context providers.

The Prompt Engine never runs Git, Azure CLI, Docker, kubectl, Ollama, or another external process. Discovery belongs to Context Engine providers. Theme files are generated implementation details and must not be hand-edited.

Generation is fingerprinted using the engine version, selected style, and prompt configuration. A normal startup reuses an unchanged theme. `Set-DevShellPromptStyle AI` changes the session style, regenerates the theme, and reloads Oh My Posh through public host orchestration. Use `-PassThru` only when the raw PromptModel is needed. `Show-DevShellPrompt` reports the active style, segment visibility, output path, and generation time.

`Reload-Profile` preserves the current session style, force-imports the module globally, and reactivates the regenerated Oh My Posh theme. It deliberately avoids self-removal, which can tear down an interactive prompt while the reload function unwinds.

Oh My Posh initialization is owned by the PowerShell profile through a globally bound host activator. This keeps Oh My Posh's global helper functions and core module independent of the `Aundy.DevShell` module lifecycle. Reloading Aundy only replaces the context-refresh wrapper; it does not tear down or duplicate Oh My Posh.

## Refresh manager and cache invalidation

`PromptRefreshManager` runs before the Oh My Posh draw. It tracks the working directory and the nearest `global.json` signature. A directory change clears only Git, DotNet, and Kubernetes provider entries; a `global.json` change in place clears only DotNet. Azure, AI, Docker, and Machine retain their normal TTL state. Between the next provider deadline and any location change, the manager reuses its last immutable context snapshot.

The generated theme contains stable `AUNDY_PROMPT_*` environment-backed slots rather than literal repository or runtime values. The manager passes fresh context to `Get-DevShellPrompt`, publishes the rendered values, and then Oh My Posh draws them. Consequently normal redraw and directory changes never regenerate theme JSON.

## Segment development

A segment registered with `Register-DevShellPromptSegment` supplies `Name`, `Enabled`, `Visible`, `Order`, `Priority`, `Render`, and `Style`. Both scriptblocks receive only a DevContext object. They must be deterministic and must not perform discovery or invoke commands. `Visible` decides eligibility; `Render` returns the literal text consumed by any renderer.

New segments require no renderer changes. Add the registration in `Initialize-DevShellPromptRegistry`, then include its registered name in one or more styles.

## Creating a custom style

Styles are declarative collections of registry names:

```powershell
Register-DevShellPromptStyle -Name MyStyle `
    -Left Time,Azure,Repository,Branch `
    -Right Docker,Kubernetes
```

The built-in styles are `Minimal`, `Developer`, `Cloud`, `AI`, and `Presentation`. `Classic` and `Compact` remain compatibility layouts from v1.

## Built-in rendering

- Time: `21:45`
- Azure: `☁ BOQ NonProd`, only while logged in
- Repository and Branch: only in a repository
- GitStatus: clean, dirty, conflict, ahead, and behind indicators from context
- DotNet: required `global.json` SDK major, otherwise current SDK major
- AI, Docker, Kubernetes, and Administrator: enabled only by their context values
