function Get-DevShellGitContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    if (-not (Get-Command -Name git -ErrorAction SilentlyContinue)) {
        return [pscustomobject]@{ Repository = $false; Branch = $null; State = 'Unavailable' }
    }
    $statusLines = @(& git status --porcelain=v1 --branch 2>$null)
    if ($LASTEXITCODE -ne 0 -or $statusLines.Count -eq 0) {
        return [pscustomobject]@{ Repository = $false; Branch = $null; State = 'Outside repository' }
    }

    $branch = ($statusLines[0] -replace '^##\s*', '') -replace '\.\.\..*$', ''
    $changes = @($statusLines | Select-Object -Skip 1)
    $conflict = $changes | Where-Object { $_ -match '^(DD|AU|UD|UA|DU|AA|UU)' } | Select-Object -First 1
    $state = if ($conflict) { 'Conflict' } elseif ($changes.Count -gt 0) { 'Modified' } else { 'Clean' }
    [pscustomobject]@{ Repository = $true; Branch = $branch; State = $state }
}
