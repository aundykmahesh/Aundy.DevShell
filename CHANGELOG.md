# Changelog

All notable changes to this project are documented here.

## [Unreleased]

## [0.3.0] - 2026-08-04

### Added

- Added immutable, independently cached Context Engine providers for PowerShell, Git, Azure, .NET, Docker, Kubernetes, AI, and machine state.
- Added the data-driven Prompt Engine with a backend-neutral `PromptModel`, segment registry, declarative styles, and generated Oh My Posh themes.
- Added Minimal, Developer, Cloud, AI, and Presentation prompt styles, plus Classic and Compact compatibility layouts.
- Added `PromptRefreshManager` for directory and `global.json` change detection with targeted provider invalidation.
- Added `Show-DevContext`, `Show-DevShellPrompt`, and `Show-DevShellDiagnostics` diagnostics.
- Added environment-backed prompt slots so fresh context renders without regenerating theme JSON.

### Fixed

- Render dirty, ahead, and behind Git states together, including `● ↑8↓2`.
- Preserve prompt state across directory changes and repeated profile reloads.
- Keep Oh My Posh helper ownership independent of the Aundy.DevShell module lifecycle.
- Prevent missing optional tools from adding records to `$Error`.
- Report the Oh My Posh CLI product version instead of Windows alias metadata.

### Performance

- Reuse immutable context snapshots until a provider deadline or location-sensitive change.
- Keep warmed prompt refresh coordination below the 5 ms target.
- Generate themes only when style, configuration, or Prompt Engine version changes.

## [0.2.0]

- Added the initial model-driven prompt and provider-based Context Engine.
- Migrated profile functions and aliases into the module.

## [0.1.0]

- Added the module foundation, configuration, profile bootstrapper, utilities, tests, and CI workflows.

[Unreleased]: https://github.com/aundykmahesh/Aundy.DevShell/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/aundykmahesh/Aundy.DevShell/releases/tag/v0.3.0
