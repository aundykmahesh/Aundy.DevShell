# Aundy.DevShell Architecture

## Overview

Aundy.DevShell separates environment discovery, prompt modeling, rendering, and host integration. The central rule is that the Prompt Engine renders data; it never discovers the environment or executes developer tools.

```text
PowerShell profile
  -> profile orchestration
  -> PromptRefreshManager
  -> Context Engine
  -> PromptModel and segment registry
  -> Oh My Posh theme renderer
  -> Oh My Posh
```

## Layers

### PowerShell profile and host integration

`profile/Microsoft.PowerShell_profile.ps1` is the composition root. It imports the module, prepares the initial context and theme, and owns Oh My Posh initialization in global session scope. Keeping host initialization outside module scope prevents Oh My Posh helpers from being removed when Aundy.DevShell reloads.

Public orchestration commands such as `Initialize-DevShellProfile`, `Reload-Profile`, and `Set-DevShellPromptStyle` coordinate lifecycle actions. `Enable-DevShellPromptRefresh` wraps the host prompt with context refresh without taking ownership of Oh My Posh internals.

### Context Engine

The Context Engine under `src/Aundy.DevShell/Context` is the only layer that discovers environment state. Providers own their external commands, defaults, TTLs, cache keys, failure isolation, and health metadata. `Get-DevContext` returns one immutable snapshot containing all provider results.

Provider caches are independent. A slow or unavailable provider cannot corrupt another provider or prevent a context snapshot from being returned.

### PromptRefreshManager

`PromptRefreshManager.ps1` bridges shell events and context acquisition. It detects working-directory and `global.json` changes, invalidates only affected provider caches, obtains a fresh `DevContext`, and passes that snapshot to the Prompt Engine.

Directory changes invalidate Git, DotNet, and Kubernetes. Azure, AI, Docker, and Machine retain their normal TTL state. Unchanged redraws reuse the last immutable snapshot until the next provider deadline.

### Prompt Engine

The Prompt Engine under `src/Aundy.DevShell/Prompt` owns prompt layout, registered segments, declarative styles, visibility, ordering, and rendering rules. Every segment implements `Name`, `Enabled`, `Visible`, `Order`, `Priority`, `Render(context)`, and `Style`.

Segments consume only `DevContext`. Adding a segment requires registry and style configuration, not renderer changes.

### Renderer and generated theme

`Build-Theme` is an Oh My Posh renderer isolated from context providers. It converts `PromptModel` into schema-version-four JSON containing stable environment-backed segment slots. `PromptRefreshManager` publishes freshly rendered values into those slots before Oh My Posh draws the prompt.

The JSON theme is generated implementation state. Users configure settings and styles rather than editing JSON. Normal prompt redraws and directory changes never regenerate the theme.

## Design principles

1. Context discovery belongs exclusively to Context Engine providers.
2. Prompt segments and renderers never execute Git, Azure CLI, Docker, kubectl, Ollama, or other external tools.
3. Context snapshots are immutable and provider failures are isolated.
4. Cache invalidation is targeted; unrelated providers retain their TTL state.
5. Styles are declarative collections of registered segments.
6. Renderers depend on `PromptModel`, not provider implementations.
7. Theme generation is deterministic and occurs only for style, configuration, or engine-version changes.
8. Profile and host initialization are idempotent and survive repeated module reloads.
9. Optional dependencies fail quietly and do not pollute `$Error`.
10. Diagnostics are explicit and do not run during normal startup.
