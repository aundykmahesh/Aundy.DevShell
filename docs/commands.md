# Command discovery

Aundy.DevShell provides a lightweight navigation layer over its PowerShell commands. It helps you discover the right command; it does not replace PowerShell's detailed help system.

## Discover commands

Run `Show-DevShell` or its short alias, `dev`, to see the complete categorized overview:

```powershell
dev
```

Pass a category to see summaries for its commands:

```powershell
dev workspace
dev prompt
dev ai
```

Pass a command name to see its purpose, related commands, and the corresponding `Get-Help` invocation:

```powershell
dev Get-Workspace
```

Other text is used as a case-insensitive search across command names, categories, summaries, and related commands:

```powershell
dev Claude
```

## Categories

Every registered command belongs to exactly one category, such as Machine Context, Developer Context, Workspace, Prompt, Diagnostics, Git, Azure, Docker, AI, Navigation, Environment, Installation, Utilities, or Testing. Categories and overview contents are generated from the central registry rather than maintained as separate display text.

## Query the registry

`Get-DevShellCommands` returns structured metadata with `Name`, `Category`, `Summary`, `RelatedCommands`, and `Visibility` properties. This makes discovery information available to scripts as well as people:

```powershell
Get-DevShellCommands |
    Where-Object Category -eq 'Workspace'
```

Registering a new command in the central registry makes it appear automatically in the appropriate discovery views.

## PowerShell help

Discovery provides orientation and links between commands. Use PowerShell help for syntax, parameters, inputs, outputs, and detailed examples:

```powershell
Get-Help Get-Workspace
Get-Help Get-Workspace -Examples
Get-Help Get-Workspace -Full
```
