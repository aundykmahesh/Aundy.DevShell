function Get-DockerContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $dockerRunning = $false
    if (Get-Command -Name docker -ErrorAction SilentlyContinue) {
        & docker info --format '{{.ServerVersion}}' 2>$null | Out-Null
        $dockerRunning = $LASTEXITCODE -eq 0
    }

    $kubectlContext = $null
    if (Get-Command -Name kubectl -ErrorAction SilentlyContinue) {
        $value = & kubectl config current-context 2>$null
        if ($LASTEXITCODE -eq 0) { $kubectlContext = [string]($value | Select-Object -First 1) }
    }
    [pscustomobject]@{ DockerRunning = $dockerRunning; KubectlContext = $kubectlContext }
}
