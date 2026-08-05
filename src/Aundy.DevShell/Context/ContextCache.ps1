$script:DevContextCache = @{}
$script:DevContextCacheLock = [object]::new()

function ConvertTo-ImmutableDevContextObject {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowNull()] $InputObject)

    if ($InputObject -is [string] -or $InputObject -is [ValueType] -or $null -eq $InputObject) { return $InputObject }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [System.Collections.IDictionary] -and $InputObject -isnot [pscustomobject]) {
        $items = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $InputObject) { $items.Add((ConvertTo-ImmutableDevContextObject -InputObject $item)) }
        return [System.Collections.ObjectModel.ReadOnlyCollection[object]]::new($items)
    }

    $properties = if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($key in $InputObject.Keys) { [pscustomobject]@{ Name = [string]$key; Value = $InputObject[$key] } }
    }
    else {
        foreach ($property in $InputObject.PSObject.Properties) { [pscustomobject]@{ Name = $property.Name; Value = $property.Value } }
    }

    $immutable = [pscustomobject]::new()
    foreach ($property in $properties) {
        $value = ConvertTo-ImmutableDevContextObject -InputObject $property.Value
        $variable = [System.Management.Automation.PSVariable]::new(
            $property.Name,
            $value,
            [System.Management.Automation.ScopedItemOptions]::ReadOnly
        )
        $immutable.PSObject.Properties.Add([System.Management.Automation.PSVariableProperty]::new($variable))
    }
    return $immutable
}

function Add-DevContextProviderMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Data,
        [Parameter(Mandatory)][bool] $Healthy,
        [Parameter(Mandatory)][double] $ElapsedMilliseconds,
        [Parameter(Mandatory)][bool] $Cached,
        [Parameter(Mandatory)][datetime] $LastRefreshUtc,
        [Parameter(Mandatory)][int] $CacheHits,
        [Parameter(Mandatory)][double] $CacheAgeMilliseconds,
        [Parameter(Mandatory)][timespan] $TimeToLive,
        [Parameter(Mandatory)][string] $RefreshPolicy,
        [string] $ErrorMessage
    )

    $values = [ordered]@{}
    foreach ($property in $Data.PSObject.Properties) { $values[$property.Name] = $property.Value }
    $values.Healthy = $Healthy
    $values.ElapsedMilliseconds = [math]::Round($ElapsedMilliseconds, 2)
    $values.Cached = $Cached
    $values.LastRefreshUtc = $LastRefreshUtc
    $values.CacheAgeMilliseconds = [math]::Round($CacheAgeMilliseconds, 2)
    $values.CacheHits = $CacheHits
    $values.TTLSeconds = $TimeToLive.TotalSeconds
    $values.RefreshPolicy = $RefreshPolicy
    $values.Error = $ErrorMessage
    ConvertTo-ImmutableDevContextObject -InputObject $values
}

function Invoke-DevContextProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable] $Registration,
        [switch] $ForceRefresh
    )

    $cacheKey = & $Registration.CacheKey
    $key = '{0}:{1}' -f $Registration.Name, $cacheKey
    $now = [datetime]::UtcNow
    $entry = $null

    [System.Threading.Monitor]::Enter($script:DevContextCacheLock)
    try {
        $entry = $script:DevContextCache[$key]
        if (-not $ForceRefresh -and $entry -and (($now - $entry.LastRefreshUtc) -lt $Registration.TimeToLive)) {
            $entry.CacheHits++
        }
        else { $entry = $null }
    }
    finally { [System.Threading.Monitor]::Exit($script:DevContextCacheLock) }

    if ($entry) {
        return Add-DevContextProviderMetadata -Data $entry.Data -Healthy $entry.Healthy `
            -ElapsedMilliseconds $entry.ElapsedMilliseconds -Cached $true -LastRefreshUtc $entry.LastRefreshUtc `
            -CacheHits $entry.CacheHits -CacheAgeMilliseconds ($now - $entry.LastRefreshUtc).TotalMilliseconds `
            -TimeToLive $Registration.TimeToLive -RefreshPolicy $Registration.RefreshPolicy -ErrorMessage $entry.Error
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $healthy = $true
    $errorMessage = $null
    try { $data = & $Registration.Command }
    catch {
        $healthy = $false
        $errorMessage = $_.Exception.Message
        $data = [pscustomobject]$Registration.Default
    }
    finally { $stopwatch.Stop() }

    $lastRefreshUtc = [datetime]::UtcNow
    $entry = @{
        Data = $data; Healthy = $healthy; Error = $errorMessage
        ElapsedMilliseconds = $stopwatch.Elapsed.TotalMilliseconds
        LastRefreshUtc = $lastRefreshUtc; CacheHits = 0
    }
    [System.Threading.Monitor]::Enter($script:DevContextCacheLock)
    try { $script:DevContextCache[$key] = $entry }
    finally { [System.Threading.Monitor]::Exit($script:DevContextCacheLock) }

    Add-DevContextProviderMetadata -Data $data -Healthy $healthy -ElapsedMilliseconds $entry.ElapsedMilliseconds `
        -Cached $false -LastRefreshUtc $lastRefreshUtc -CacheHits 0 -CacheAgeMilliseconds 0 `
        -TimeToLive $Registration.TimeToLive -RefreshPolicy $Registration.RefreshPolicy -ErrorMessage $errorMessage
}

function Clear-DevContextCache {
    [CmdletBinding()]
    param([string] $Provider)

    [System.Threading.Monitor]::Enter($script:DevContextCacheLock)
    try {
        if (-not $Provider) { $script:DevContextCache.Clear(); return }
        @($script:DevContextCache.Keys) |
            Where-Object { $_ -like "${Provider}:*" } |
            ForEach-Object { [void]$script:DevContextCache.Remove($_) }
    }
    finally { [System.Threading.Monitor]::Exit($script:DevContextCacheLock) }
}

function Clear-LocationSensitiveDevContextCache {
    [CmdletBinding()]
    param()
    foreach ($provider in 'Git','Workspace','DotNet','Kubernetes') { Clear-DevContextCache -Provider $provider }
}
