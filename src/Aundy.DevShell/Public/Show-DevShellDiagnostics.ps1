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
    $providerHealth = foreach ($name in 'PowerShell', 'Git', 'Azure', 'DotNet', 'Docker', 'Kubernetes', 'AI', 'Machine') {
        $provider = $context.$name
        [pscustomobject]@{
            Provider = $name
            Healthy = $provider.Healthy
            ElapsedMilliseconds = $provider.ElapsedMilliseconds
            Cached = $provider.Cached
            CacheAgeMilliseconds = $provider.CacheAgeMilliseconds
            CacheHits = $provider.CacheHits
            LastRefreshUtc = $provider.LastRefreshUtc
        }
    }

    [pscustomobject]@{
        PowerShellVersion = $context.Machine.PowerShellVersion
        OhMyPoshVersion   = $ohMyPoshVersion
        Theme             = $themePath
        StartupTimeMs     = [math]::Round($script:ModuleImportMilliseconds, 2)
        AzureStatus       = if ($context.Azure.LoggedIn) { $context.Azure.Subscription } else { 'Disconnected' }
        GitStatus         = if ($context.Git.IsGitRepository) { "$($context.Git.Branch) ($(if ($context.Git.Dirty) { 'Modified' } else { 'Clean' }))" } else { 'Outside repository' }
        SettingsFile      = Resolve-DevShellSettingsPath
        PromptStyle       = $promptSettings.Style
        ProviderHealth    = $providerHealth
        CacheHits         = ($providerHealth | Measure-Object -Property CacheHits -Sum).Sum
        CacheAgeMs        = ($providerHealth | Measure-Object -Property CacheAgeMilliseconds -Maximum).Maximum
    }
}
