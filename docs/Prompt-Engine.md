# Prompt Engine v2

## Architecture and lifecycle

The profile calls `Get-DevContext`, then passes that immutable snapshot to `Get-DevShellPrompt`. The Prompt Engine evaluates registered segments and produces a backend-neutral `PromptModel` with `Left`, `Right`, `Transient`, and `Secondary` collections. `Build-Theme` is the isolated Oh My Posh renderer; it converts visible model entries to generated JSON without knowing about context providers.

The Prompt Engine never runs Git, Azure CLI, Docker, kubectl, Ollama, or another external process. Discovery belongs to Context Engine providers. Theme files are generated implementation details and must not be hand-edited.

Generation is fingerprinted using the engine version, selected style, and prompt configuration. A normal startup reuses an unchanged theme. `Set-DevShellPromptStyle AI` changes the session style, regenerates the theme, and reloads Oh My Posh through public host orchestration. Use `-PassThru` only when the raw PromptModel is needed. `Show-DevShellPrompt` reports the active style, segment visibility, output path, and generation time.

`Reload-Profile` preserves the current session style, force-imports the module globally, and reactivates the regenerated Oh My Posh theme. It deliberately avoids self-removal, which can tear down an interactive prompt while the reload function unwinds.

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
