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
    $promptStyle = Get-DevShellPromptStyle
    $themePath = Resolve-DevShellThemePath
    $context = Get-DevContext
    $ohMyPosh = Get-Command -Name oh-my-posh -ErrorAction Ignore
    $ohMyPoshVersion = 'Unavailable'
    if ($ohMyPosh) {
        $reportedVersion = [string]((& $ohMyPosh.Source version 2>$null) | Select-Object -First 1)
        if ($LASTEXITCODE -eq 0 -and $reportedVersion) { $ohMyPoshVersion = $reportedVersion.Trim() }
        elseif ($ohMyPosh.Version) { $ohMyPoshVersion = $ohMyPosh.Version.ToString() }
    }
    $providerHealth = foreach ($name in 'PowerShell', 'Git', 'Workspace', 'Azure', 'DotNet', 'Docker', 'Kubernetes', 'AI', 'Machine') {
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
        Workspace         = $context.Workspace.Name
        WorkspaceRoot     = $context.Workspace.Root
        WorkspaceDiscoveryTimeMs = $context.Workspace.ElapsedMilliseconds
        WorkspaceCached   = $context.Workspace.Cached
        RepositoryCount   = @($context.Workspace.Repositories).Count
        SolutionCount     = @($context.Workspace.Solutions).Count
        ProjectCount      = @($context.Workspace.Projects).Count
        SettingsFile      = Resolve-DevShellSettingsPath
        PromptStyle       = $promptSettings.Style
        PromptRenderer    = $promptStyle.Renderer
        PromptTheme       = $promptStyle.Theme
        PromptRegistryCount = @(Get-DevShellPromptStyles).Count
        ProviderHealth    = $providerHealth
        CacheHits         = ($providerHealth | Measure-Object -Property CacheHits -Sum).Sum
        CacheAgeMs        = ($providerHealth | Measure-Object -Property CacheAgeMilliseconds -Maximum).Maximum
    }
}
