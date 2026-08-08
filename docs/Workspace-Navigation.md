# Configured workspace navigation

Configured navigation is a Workspace Engine capability for frequently used source folders. It is separate from discovered workspaces: `Get-DevLocation` reads explicit Settings Engine definitions, while `Get-Workspace` discovers workspace structure from the current path. Neither the Prompt Engine nor the Workflow Engine scans navigation folders.

## Configuration

`Settings.psd1` defines a portable root and parent-relative children:

```powershell
Navigation = @{
    Locations = @(
        @{ Name='Repos'; Path='%USERPROFILE%\source\repos'; Shortcut='repos'; Enabled=$true }
        @{ Name='SharedDomain'; Path='SharedDomain'; Parent='Repos'; Shortcut='shared'; Enabled=$true }
        @{ Name='CBI'; Path='CBI'; Parent='Repos'; Shortcut='cbi'; Enabled=$true }
        @{ Name='CE'; Path='CE'; Parent='Repos'; Shortcut='ce'; Enabled=$true }
    )
}
```

Environment variables are expanded without changing the caller's environment. Relative child paths are resolved against the named parent and cannot escape that parent. Add deeper locations explicitly using the same model; DevShell never enumerates child directories to infer them.

Names and shortcuts must be unique case-insensitively. Parents must exist in the configuration, parent cycles are rejected, and disabled locations are excluded from normal listing and navigation. Shortcut values are validated metadata only: dynamic shortcut generation is intentionally disabled to avoid command collisions. Existing compatibility commands such as `CBI`, `CE`, and `SharedDomain` delegate to the canonical command.

## Commands

```powershell
Get-DevLocation
Get-DevLocation -Name CBI
Get-DevLocation -Refresh

Set-DevLocation Repos
Set-DevLocation SharedDomain
Set-DevLocation -Name CBI
Set-DevLocation CE -WhatIf
```

`Get-DevLocation` returns structured definitions without checking every folder or scanning the filesystem. `Set-DevLocation` checks the selected folder immediately before navigation and uses `Set-Location -LiteralPath`. If a folder is missing, update its definition or create it outside DevShell; the command never creates directories.

Validated configuration-derived metadata is cached in memory. A changed configuration signature or `-Refresh` rebuilds the registry. Filesystem existence is not cached.

Workflow working directories remain independent. A future workflow definition may refer to a named location only through a Workspace Engine public resolver; workflows must never read `Navigation.Locations` directly.
