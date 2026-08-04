function Show-DevShellDiagnostics {
    <#
    .SYNOPSIS
    Displays diagnostics for the Aundy.DevShell prompt environment.
    .DESCRIPTION
    Collects PowerShell, Oh My Posh, theme, startup, Azure, Git, settings, and prompt-style information on demand. Diagnostics are never collected automatically.
    .EXAMPLE
    Show-DevShellDiagnostics
    .OUTPUTS
    PSCustomObject
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $promptSettings = Get-DevShellPromptSettings
    $themePath = Resolve-DevShellThemePath
    $context = Get-DevContext
    $ohMyPosh = Get-Command -Name oh-my-posh -ErrorAction SilentlyContinue
    $ohMyPoshVersion = if ($ohMyPosh) { $ohMyPosh.Version.ToString() } else { 'Unavailable' }

    [pscustomobject]@{
        PowerShellVersion = $context.PowerShellVersion
        OhMyPoshVersion   = $ohMyPoshVersion
        Theme             = $themePath
        StartupTimeMs     = [math]::Round($script:ModuleImportMilliseconds, 2)
        AzureStatus       = if ($context.AzureSubscription) { $context.AzureSubscription } else { 'Disconnected' }
        GitStatus         = if ($context.Repository) { "$($context.GitBranch) ($(if ($context.GitDirty) { 'Modified' } else { 'Clean' }))" } else { 'Outside repository' }
        SettingsFile      = Resolve-DevShellSettingsPath
        PromptStyle       = $promptSettings.Style
    }
}
