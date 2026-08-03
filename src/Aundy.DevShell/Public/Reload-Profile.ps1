function Reload-Profile {
    <#
    .SYNOPSIS
    Reloads Aundy.DevShell and regenerates its prompt theme.
    .DESCRIPTION
    Removes the loaded Aundy.DevShell module, imports the latest local module version, and regenerates the Oh My Posh theme. Prompt installation remains the responsibility of the PowerShell profile.
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

    Remove-Module -Name Aundy.DevShell -Force -ErrorAction Stop
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
    New-DevShellPromptTheme | Out-Null

    $stopwatch.Stop()
    Write-Information "✓ Aundy.DevShell reloaded in $([math]::Round($stopwatch.Elapsed.TotalMilliseconds)) ms" -InformationAction Continue
}
