function New-DevShellPromptSegment {
    param([string]$Name, [int]$Order, [int]$Priority, [hashtable]$Style,
        [scriptblock]$Visible, [scriptblock]$Render, [bool]$Enabled = $true)
    [ordered]@{ Name=$Name; Enabled=$Enabled; Visible=$Visible; Order=$Order; Priority=$Priority; Render=$Render; Style=$Style }
}

function Register-DevShellPromptSegment {
    param([Parameter(Mandatory)][hashtable]$Segment)
    foreach ($member in 'Name','Enabled','Visible','Order','Priority','Render','Style') {
        if (-not $Segment.Contains($member)) { throw "Prompt segment is missing '$member'." }
    }
    $script:PromptSegmentRegistry[$Segment.Name] = $Segment
}

function Register-DevShellPromptStyle {
    param([string]$Name, [string[]]$Left=@(), [string[]]$Right=@(), [string[]]$Transient=@(), [string[]]$Secondary=@())
    $script:PromptStyleRegistry[$Name] = [ordered]@{ Name=$Name; Left=$Left; Right=$Right; Transient=$Transient; Secondary=$Secondary }
}

function Get-DevShellPromptStyleDefinition {
    param([Parameter(Mandatory)][string]$Name)
    if (-not $script:PromptStyleRegistry.ContainsKey($Name)) { throw "Unknown prompt style '$Name'." }
    $script:PromptStyleRegistry[$Name]
}

function Initialize-DevShellPromptRegistry {
    param([Parameter(Mandatory)][hashtable]$Settings)
    if ($script:PromptSegmentRegistry -and $script:PromptStyleRegistry) { return }
    $script:PromptSegmentRegistry = @{}
    $script:PromptStyleRegistry = @{}
    $colour = $Settings.Colors
    $styleFor = { param($name) [ordered]@{ Foreground = $colour[$name]; Type = 'text' } }
    Register-DevShellPromptSegment (New-DevShellPromptSegment Time 10 10 (&$styleFor Time) { $true } {
        param($c) $c.PowerShell.CapturedAt.ToString('HH:mm')
    })
    Register-DevShellPromptSegment (New-DevShellPromptSegment Azure 20 90 (&$styleFor Azure) { param($c) [bool]$c.Azure.LoggedIn } {
        param($c) $name = [string]$c.Azure.Subscription; if ($Settings.AzureAliases.ContainsKey($name)) { $name=$Settings.AzureAliases[$name] }; "$($Settings.Symbols.Azure) $name"
    })
    Register-DevShellPromptSegment (New-DevShellPromptSegment Repository 30 50 (&$styleFor Folder) {
        param($c) [bool]($c.Git.IsGitRepository -or ($Settings.LocationDisplay -eq 'Workspace' -and $c.Workspace.IsWorkspace))
    } {
        param($c)
        if ($Settings.LocationDisplay -eq 'Workspace' -and $c.Workspace.IsWorkspace) { return [string]$c.Workspace.Name }
        [string]$c.Git.Repository
    })
    Register-DevShellPromptSegment (New-DevShellPromptSegment Branch 40 50 (&$styleFor Git) { param($c) [bool]$c.Git.IsGitRepository } { param($c) [string]$c.Git.Branch })
    Register-DevShellPromptSegment (New-DevShellPromptSegment GitStatus 50 60 (&$styleFor Git) { param($c) [bool]$c.Git.IsGitRepository } {
        param($c)
        $state = if ($c.Git.Dirty) { [string][char]0x25cf } else { '' }
        $sync = "$(if($c.Git.Ahead -gt 0){[char]0x2191 + $c.Git.Ahead})$(if($c.Git.Behind -gt 0){[char]0x2193 + $c.Git.Behind})"
        if ($sync) { return (@($state,$sync) | Where-Object { $_ }) -join ' ' }
        if ($state) { return $state }; [char]0x2714
    })
    Register-DevShellPromptSegment (New-DevShellPromptSegment DotNet 60 30 (&$styleFor DotNet) { param($c) [bool]($c.DotNet.RequiredSdk -or $c.DotNet.CurrentSdk) } {
        param($c) $v=if($c.DotNet.GlobalJsonPresent -and $c.DotNet.RequiredSdk){$c.DotNet.RequiredSdk}else{$c.DotNet.CurrentSdk}; ".NET $(([string]$v -split '\.')[0])"
    })
    Register-DevShellPromptSegment (New-DevShellPromptSegment AI 70 40 (&$styleFor AI) { param($c) [bool]$c.AI.RuntimeAvailable } {
        param($c) if($c.AI.OllamaRunning){'🤖 Ollama'}elseif($c.AI.OpenWebUIRunning){'🤖 AI'}else{'🤖'}
    })
    Register-DevShellPromptSegment (New-DevShellPromptSegment Docker 80 30 (&$styleFor Docker) { param($c) [bool]$c.Docker.Running } { '🐳' })
    Register-DevShellPromptSegment (New-DevShellPromptSegment Kubernetes 90 30 (&$styleFor Kubernetes) { param($c) [bool]$c.Kubernetes.Context } { param($c) "☸ $($c.Kubernetes.Context)" })
    Register-DevShellPromptSegment (New-DevShellPromptSegment Administrator 100 100 (&$styleFor Administrator) { param($c) [bool]$c.Machine.Administrator } { '#' })

    Register-DevShellPromptStyle Minimal -Left Time,Azure
    Register-DevShellPromptStyle Developer -Left Time,Azure,Repository,Branch,GitStatus,DotNet,Docker,AI,Kubernetes,Administrator
    Register-DevShellPromptStyle Cloud -Left Azure,Repository,Branch,Time,Administrator
    Register-DevShellPromptStyle AI -Left AI,Repository,Branch,GitStatus,DotNet,Time,Administrator
    Register-DevShellPromptStyle Presentation -Left Repository,Branch,Azure
    # Compatibility names from Prompt Engine v1.
    Register-DevShellPromptStyle Classic -Left Time,Azure,Repository,Branch,GitStatus,Administrator
    Register-DevShellPromptStyle Compact -Left Repository,Branch,GitStatus,Administrator -Right Time,Azure
}
