# Workspace Engine

The Workspace Engine discovers developer context and supplies it to `Get-DevContext`. The Prompt Engine renders that context and never scans the filesystem.

## Discovery

Discovery starts at the supplied path (the current directory by default) and walks upward, like Git repository discovery. It has no configured drive or repository-container dependency. A directory is marked by `.git`, `*.sln`, `*.slnx`, `global.json`, `Directory.Build.props`, `Directory.Build.targets`, or `Directory.Packages.props`.

The nearest `.git` ancestor is the current repository. The outermost marked ancestor is the workspace root, allowing a marked parent workspace to contain nested repositories. If no ancestor has a marker, `IsWorkspace` is false. Once the root is known, repositories, solutions, and C# projects are inventoried below it. A future `workspace.json` marker and metadata reader can be added without changing the public contract; it is not parsed today.

## Cache

Workspace snapshots are keyed by current path and cached for 300 seconds. A directory change invalidates the location-sensitive Workspace provider immediately. `Get-Workspace -Refresh` forces rediscovery. Cache metadata and discovery duration are exposed on the returned context.

## Public API

- `Get-Workspace` returns the workspace model.
- `Get-WorkspaceRepositories`, `Get-WorkspaceSolutions`, and `Get-WorkspaceProjects` return inventories.
- `Show-Workspace` returns a concise display object with counts.
- `Get-DevContext` exposes the same model as `Workspace`.

Set `Prompt.LocationDisplay` to `Repository` or `Workspace`. Prompt rendering reads only `DevContext`.
