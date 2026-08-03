function Resolve-DevShellThemePath {
    [CmdletBinding()]
    [OutputType([string])]
    param([string] $Path)

    $configuredPath = if ($Path) { $Path } else { (Get-DevShellPromptSettings).ThemePath }
    if ([string]::IsNullOrWhiteSpace($configuredPath)) {
        throw 'Prompt.ThemePath must specify the generated theme location.'
    }
    if ([System.IO.Path]::IsPathRooted($configuredPath)) {
        return [System.IO.Path]::GetFullPath($configuredPath)
    }
    [System.IO.Path]::GetFullPath((Join-Path $script:ModuleRoot $configuredPath))
}
