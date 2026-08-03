function New-GitPromptSegment {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable] $Settings)

    try {
        if (-not (Get-Command -Name git -ErrorAction SilentlyContinue)) { return $null }
        $symbols = $Settings.Symbols
        [ordered]@{
        Name       = 'Git'
        Type       = 'git'
        Template   = "$($symbols.Git) {{ .HEAD }} {{ if or (gt .Working.Unmerged 0) (gt .Staging.Unmerged 0) }}$($symbols.Failed){{ else if or (.Working.Changed) (.Staging.Changed) }}$($symbols.Dirty){{ else }}$($symbols.Clean){{ end }}"
        Foreground = $Settings.Colors.Git
        Options    = [ordered]@{
            fetch_status        = $true
            fetch_upstream_icon = $false
            source              = 'cli'
        }
        }
    }
    catch { return $null }
}
