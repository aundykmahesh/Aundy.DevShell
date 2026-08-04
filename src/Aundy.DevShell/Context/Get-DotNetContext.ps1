$script:DotNetContextProvider = @{
    Name = 'DotNet'; TimeToLive = [timespan]::FromMinutes(5); RefreshPolicy = 'OnExpiry'
    CacheKey = { (Get-Location).Path }; Command = { Get-DotNetContext }
    Default = [ordered]@{ Version = $null; CurrentSdk = $null; Sdks = @(); Runtimes = @(); GlobalJsonPresent = $false; GlobalJsonPath = $null; RequiredSdk = $null; RuntimeCount = 0; SdkCount = 0 }
}

function Find-DevContextGlobalJson {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $StartPath)

    $directory = Get-Item -LiteralPath $StartPath -ErrorAction Stop
    if (-not $directory.PSIsContainer) { $directory = $directory.Directory }
    $repositoryRoot = $null
    $cursor = $directory
    while ($cursor) {
        if (Test-Path -LiteralPath (Join-Path $cursor.FullName '.git')) { $repositoryRoot = $cursor.FullName; break }
        $cursor = $cursor.Parent
    }
    if (-not $repositoryRoot) { return $null }

    $cursor = $directory
    while ($cursor) {
        $candidate = Join-Path $cursor.FullName 'global.json'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
        if ($cursor.FullName -eq $repositoryRoot) { break }
        $cursor = $cursor.Parent
    }
    return $null
}

function Get-DotNetContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $result = [ordered]@{ Version = $null; CurrentSdk = $null; Sdks = @(); Runtimes = @(); GlobalJsonPresent = $false; GlobalJsonPath = $null; RequiredSdk = $null; RuntimeCount = 0; SdkCount = 0 }
    $globalJsonPath = Find-DevContextGlobalJson -StartPath (Get-Location).Path
    if ($globalJsonPath) {
        $result.GlobalJsonPresent = $true
        $result.GlobalJsonPath = $globalJsonPath
        try { $result.RequiredSdk = (Get-Content -LiteralPath $globalJsonPath -Raw | ConvertFrom-Json -ErrorAction Stop).sdk.version }
        catch { $result.RequiredSdk = $null }
    }

    if (-not (Get-Command -Name dotnet -ErrorAction Ignore)) { return ConvertTo-ImmutableDevContextObject $result }
    $version = & dotnet --version 2>$null
    if ($LASTEXITCODE -eq 0) { $result.Version = [string]($version | Select-Object -First 1); $result.CurrentSdk = $result.Version }
    $sdks = @(& dotnet --list-sdks 2>$null)
    if ($LASTEXITCODE -eq 0) { $result.Sdks = @($sdks | ForEach-Object { [string]$_ }) }
    $runtimes = @(& dotnet --list-runtimes 2>$null)
    if ($LASTEXITCODE -eq 0) { $result.Runtimes = @($runtimes | ForEach-Object { [string]$_ }) }
    $result.SdkCount = $result.Sdks.Count
    $result.RuntimeCount = $result.Runtimes.Count
    ConvertTo-ImmutableDevContextObject $result
}
