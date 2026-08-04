function Reload-Profile {
    <#
    .SYNOPSIS
    Reloads Aundy.DevShell and regenerates its prompt theme.
    .DESCRIPTION
    Preserves the active prompt style, reloads the module, regenerates the theme, and reactivates Oh My Posh in the current session.
    .EXAMPLE
    Reload-Profile
    .OUTPUTS
    None.
    .NOTES
    The elapsed reload time is displayed after successful initialization.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Justification = 'Sprint acceptance criteria requires the Reload-Profile public command.')]
    [CmdletBinding()]
    param()

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $loadedModule = Get-Module -Name Aundy.DevShell | Select-Object -First 1
    if (-not $loadedModule) {
        throw 'Aundy.DevShell is not currently loaded.'
    }
    $manifestPath = Join-Path $loadedModule.ModuleBase 'Aundy.DevShell.psd1'
    $activeStyle = (Get-DevShellPromptSettings).Style

    Remove-Module -Name Aundy.DevShell -Force -ErrorAction Stop
    # This function executes in module scope. Without -Global, the replacement
    # becomes a nested module and is discarded when the removed module unwinds.
    Import-Module -Name $manifestPath -Force -Global -ErrorAction Stop
    Set-DevShellPromptStyle -Style $activeStyle

    $stopwatch.Stop()
    Write-Information "✓ Aundy.DevShell reloaded in $([math]::Round($stopwatch.Elapsed.TotalMilliseconds)) ms" -InformationAction Continue
}
