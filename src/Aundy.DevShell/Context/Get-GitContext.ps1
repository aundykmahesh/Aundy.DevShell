function Get-GitContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    if (-not (Get-Command -Name git -ErrorAction SilentlyContinue)) {
        return [pscustomobject]@{ Repository = $null; GitBranch = $null; GitDirty = $false; GitAhead = 0; GitBehind = 0 }
    }

    $status = @(& git status --porcelain=v1 --branch 2>$null)
    if ($LASTEXITCODE -ne 0 -or $status.Count -eq 0) {
        return [pscustomobject]@{ Repository = $null; GitBranch = $null; GitDirty = $false; GitAhead = 0; GitBehind = 0 }
    }

    $root = & git rev-parse --show-toplevel 2>$null
    $header = [string]$status[0]
    $branch = ($header -replace '^##\s*', '') -replace '\.\.\..*$', '' -replace '\s+\[.*$', ''
    $ahead = if ($header -match 'ahead (\d+)') { [int]$Matches[1] } else { 0 }
    $behind = if ($header -match 'behind (\d+)') { [int]$Matches[1] } else { 0 }
    [pscustomobject]@{
        Repository = if ($root) { [string]($root | Select-Object -First 1) } else { (Get-Location).Path }
        GitBranch  = $branch
        GitDirty   = $status.Count -gt 1
        GitAhead   = $ahead
        GitBehind  = $behind
    }
}
