function Resolve-DevShellSettingsPath {
    [CmdletBinding()]
    [OutputType([string])]
    param([string] $Path)

    if ($Path) {
        return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    }
    if ($env:AUNDY_DEVSHELL_SETTINGS) {
        return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($env:AUNDY_DEVSHELL_SETTINGS)
    }
    Join-Path $script:ModuleRoot 'Settings.psd1'
}
