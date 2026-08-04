$script:GitContextProvider = @{
    Name = 'Git'; TimeToLive = [timespan]::FromSeconds(2); RefreshPolicy = 'OnExpiry'
    CacheKey = { (Get-Location).Path }; Command = { Get-GitContext }
    Default = [ordered]@{ Repository = $null; Root = $null; Branch = $null; Dirty = $false; Ahead = 0; Behind = 0; Commit = $null; Author = $null; IsGitRepository = $false }
}

function Get-GitContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $result = [ordered]@{ Repository = $null; Root = $null; Branch = $null; Dirty = $false; Ahead = 0; Behind = 0; Commit = $null; Author = $null; IsGitRepository = $false }
    if (-not (Get-Command -Name git -ErrorAction SilentlyContinue)) { return ConvertTo-ImmutableDevContextObject $result }

    $status = @(& git status --porcelain=v1 --branch 2>$null)
    if ($LASTEXITCODE -ne 0 -or $status.Count -eq 0) { return ConvertTo-ImmutableDevContextObject $result }

    $root = [string]((& git rev-parse --show-toplevel 2>$null) | Select-Object -First 1)
    if ($LASTEXITCODE -ne 0 -or -not $root) { return ConvertTo-ImmutableDevContextObject $result }
    $header = [string]$status[0]
    $result.Root = $root
    $result.Repository = Split-Path -Path $root -Leaf
    $result.Branch = ($header -replace '^##\s*', '') -replace '\.\.\..*$', '' -replace '\s+\[.*$', ''
    $result.Dirty = $status.Count -gt 1
    $result.Ahead = if ($header -match 'ahead (\d+)') { [int]$Matches[1] } else { 0 }
    $result.Behind = if ($header -match 'behind (\d+)') { [int]$Matches[1] } else { 0 }
    $identity = [string]((& git log -1 --format='%H%x00%an' 2>$null) | Select-Object -First 1)
    if ($LASTEXITCODE -eq 0 -and $identity) {
        $parts = $identity -split "`0", 2
        $result.Commit = $parts[0]
        if ($parts.Count -gt 1) { $result.Author = $parts[1] }
    }
    $result.IsGitRepository = $true
    ConvertTo-ImmutableDevContextObject $result
}
