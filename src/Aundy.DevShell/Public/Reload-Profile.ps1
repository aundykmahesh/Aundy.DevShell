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

    # Do not remove the module from inside one of its own functions. The removal
    # unwinds after this command returns and can tear down the newly installed
    # interactive prompt. A forced global import safely replaces the module.
    Import-Module -Name $manifestPath -Force -Global -DisableNameChecking -ErrorAction Stop
    Set-DevShellPromptStyle -Style $activeStyle -Restore

    $stopwatch.Stop()
    Write-Information "✓ Aundy.DevShell reloaded in $([math]::Round($stopwatch.Elapsed.TotalMilliseconds)) ms" -InformationAction Continue
}
