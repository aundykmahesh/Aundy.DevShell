function Get-DevShellSettings {
    <#
    .SYNOPSIS
    Gets the active Aundy.DevShell configuration.
    .DESCRIPTION
    Loads the default module settings or a PowerShell data file supplied by the caller.
    .PARAMETER Path
    An optional path to a trusted PowerShell data file.
    .EXAMPLE
    Get-DevShellSettings
    .EXAMPLE
    Get-DevShellSettings -Path "$HOME/.config/Aundy.DevShell/Settings.psd1"
    .OUTPUTS
    System.Collections.Hashtable
    .NOTES
    Set AUNDY_DEVSHELL_SETTINGS to select a user-specific settings file by default.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([string] $Path)

    Get-Settings -Path $Path
}
