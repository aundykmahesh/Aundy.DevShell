function Show-DevContext {
    <#
    .SYNOPSIS
    Displays the current developer context in grouped provider sections.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $context = Get-DevContext
    $builder = [System.Text.StringBuilder]::new()
    $sections = [ordered]@{
        Machine = [ordered]@{ User = $context.Machine.User; Computer = $context.Machine.Computer; OS = $context.Machine.OS; PowerShell = $context.Machine.PowerShellVersion; Administrator = $context.Machine.Administrator }
        Git = [ordered]@{ Repository = $context.Git.Repository; Root = $context.Git.Root; Branch = $context.Git.Branch; Dirty = $context.Git.Dirty; Ahead = $context.Git.Ahead; Behind = $context.Git.Behind }
        Azure = [ordered]@{ Subscription = $context.Azure.Subscription; Environment = $context.Azure.Environment; Account = $context.Azure.Account; LoggedIn = $context.Azure.LoggedIn }
        '.NET' = [ordered]@{ Version = $context.DotNet.Version; 'Current SDK' = $context.DotNet.CurrentSdk; 'SDK Count' = $context.DotNet.SdkCount; 'Runtime Count' = $context.DotNet.RuntimeCount; 'global.json' = $context.DotNet.GlobalJsonPath }
        Docker = [ordered]@{ Running = $context.Docker.Running; Context = $context.Docker.Context; Version = $context.Docker.Version; Containers = $context.Docker.ContainersRunning }
        Kubernetes = [ordered]@{ Available = $context.Kubernetes.Available; Context = $context.Kubernetes.Context }
        AI = [ordered]@{ Runtime = $context.AI.RuntimeAvailable; Ollama = $context.AI.OllamaRunning; 'Open WebUI' = $context.AI.OpenWebUIRunning; 'Cloudflare Tunnel' = $context.AI.CloudflareTunnelRunning }
    }

    foreach ($section in $sections.GetEnumerator()) {
        if ($builder.Length -gt 0) { [void]$builder.AppendLine() }
        [void]$builder.AppendLine($section.Key)
        [void]$builder.AppendLine('-' * $section.Key.Length)
        foreach ($item in $section.Value.GetEnumerator()) {
            $value = if ($null -eq $item.Value -or $item.Value -eq '') { 'Unavailable' } else { $item.Value }
            [void]$builder.AppendLine(('{0}: {1}' -f $item.Key, $value))
        }
    }
    $builder.ToString().TrimEnd()
}
