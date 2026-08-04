$script:DockerContextProvider = @{
    Name = 'Docker'; TimeToLive = [timespan]::FromSeconds(10); RefreshPolicy = 'OnExpiry'
    CacheKey = { 'Default' }; Command = { Get-DockerContext }
    Default = [ordered]@{ Running = $false; Context = $null; Version = $null; ContainersRunning = 0 }
}

function Get-DockerContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $result = [ordered]@{ Running = $false; Context = $null; Version = $null; ContainersRunning = 0 }
    if (-not (Get-Command -Name docker -ErrorAction Ignore)) { return ConvertTo-ImmutableDevContextObject $result }

    $dockerContext = & docker context show 2>$null
    if ($LASTEXITCODE -eq 0) { $result.Context = [string]($dockerContext | Select-Object -First 1) }
    $version = & docker version --format '{{.Server.Version}}' 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $version) { return ConvertTo-ImmutableDevContextObject $result }
    $result.Running = $true
    $result.Version = [string]($version | Select-Object -First 1)
    $containers = @(& docker ps --filter status=running --quiet 2>$null)
    if ($LASTEXITCODE -eq 0) { $result.ContainersRunning = @($containers | Where-Object { $_ }).Count }
    ConvertTo-ImmutableDevContextObject $result
}
