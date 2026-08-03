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
    $azure = Get-DevShellAzureContext
    $git = Get-DevShellGitContext
    $ohMyPosh = Get-Command -Name oh-my-posh -ErrorAction SilentlyContinue
    $ohMyPoshVersion = if ($ohMyPosh) { (& $ohMyPosh.Source version | Select-Object -First 1) } else { 'Unavailable' }

    [pscustomobject]@{
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        OhMyPoshVersion   = $ohMyPoshVersion
        Theme             = $themePath
        StartupTimeMs     = [math]::Round($script:ModuleImportMilliseconds, 2)
        AzureStatus       = if ($azure -and $azure.Connected) { "$($azure.Subscription) ($($azure.Provider))" } else { 'Disconnected' }
        GitStatus         = if ($git.Repository) { "$($git.Branch) ($($git.State))" } else { $git.State }
        SettingsFile      = Resolve-DevShellSettingsPath
        PromptStyle       = $promptSettings.Style
    }
}
