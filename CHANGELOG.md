# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- Matured the Context Engine into immutable nested provider objects with expanded .NET, Git, Azure, Docker, Kubernetes, AI, and machine context plus cache-health telemetry.
- Added the Context Engine with independently cached providers, immutable context snapshots, failure isolation, diagnostics, and provider-focused tests.
- Initial module foundation, configuration, profile bootstrapper, utility commands, tests, and CI workflows.
- Migrated all legacy profile functions and aliases into module-owned public scripts.
- Added the model-driven Prompt Engine with configurable segments, three layouts, deterministic Oh My Posh theme generation, and performance tests.
- Polished the Prompt Engine with Azure CLI/Az context support, abbreviated folders, concise Git state, asynchronous cached initialization, structured diagnostics, and complete module reload behavior.
# Sprint 3 – Prompt Engine v2

- Added a context-only PromptModel, segment/style registries, and isolated Oh My Posh renderer.
- Added Minimal, Developer, Cloud, AI, and Presentation styles and all environment segments.
- Added fingerprinted theme generation and `Show-DevShellPrompt` diagnostics.
