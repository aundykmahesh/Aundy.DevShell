function Show-DevContext {
    <#
    .SYNOPSIS
    Displays a readable diagnostic view of the current developer context.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $context = Get-DevContext
    [pscustomobject]@{
        'PowerShell Version' = $context.PowerShellVersion
        Administrator       = $context.Administrator
        Directory           = $context.CurrentDirectory
        Git                 = if ($context.Repository) { '{0} ({1}; ahead {2}, behind {3})' -f $context.GitBranch, $(if ($context.GitDirty) { 'dirty' } else { 'clean' }), $context.GitAhead, $context.GitBehind } else { 'Outside repository' }
        Azure               = if ($context.AzureSubscription) { '{0} [{1}]' -f $context.AzureSubscription, $context.AzureEnvironment } else { 'Unavailable' }
        Docker              = if ($context.DockerRunning) { 'Running' } else { 'Not running or unavailable' }
        Kubectl             = if ($context.KubectlContext) { $context.KubectlContext } else { 'Unavailable' }
        '.NET'               = if ($context.DotNetVersion) { $context.DotNetVersion } else { 'Unavailable' }
        'AI Runtime'        = if ($context.AIRuntimeAvailable) { 'Available' } else { 'Unavailable' }
        User                = $context.CurrentUser
        Computer            = $context.ComputerName
        'Operating System'  = $context.OperatingSystem
        'Provider Failures' = $context.ProviderFailures -join '; '
    }
}
