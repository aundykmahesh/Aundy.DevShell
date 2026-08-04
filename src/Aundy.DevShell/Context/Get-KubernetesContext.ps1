$script:KubernetesContextProvider = @{
    Name = 'Kubernetes'; TimeToLive = [timespan]::FromSeconds(10); RefreshPolicy = 'OnExpiry'
    CacheKey = { 'Default' }; Command = { Get-KubernetesContext }
    Default = [ordered]@{ Available = $false; Context = $null }
}

function Get-KubernetesContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $result = [ordered]@{ Available = $false; Context = $null }
    if (-not (Get-Command -Name kubectl -ErrorAction Ignore)) { return ConvertTo-ImmutableDevContextObject $result }
    $value = & kubectl config current-context 2>$null
    if ($LASTEXITCODE -eq 0) {
        $result.Available = $true
        $result.Context = [string]($value | Select-Object -First 1)
    }
    ConvertTo-ImmutableDevContextObject $result
}
