$script:DevContextCache = @{}
$script:DevContextCacheLock = [object]::new()

function Get-CachedDevContextProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][timespan] $TimeToLive,
        [Parameter(Mandatory)][scriptblock] $Provider,
        [string] $CacheKey = 'Default'
    )

    if ($TimeToLive -le [timespan]::Zero) { return & $Provider }

    $key = '{0}:{1}' -f $Name, $CacheKey
    $now = [datetime]::UtcNow
    [System.Threading.Monitor]::Enter($script:DevContextCacheLock)
    try {
        $entry = $script:DevContextCache[$key]
        if ($entry -and (($now - $entry.CreatedAt) -lt $TimeToLive)) {
            return $entry.Value
        }
    }
    finally { [System.Threading.Monitor]::Exit($script:DevContextCacheLock) }

    $value = & $Provider
    [System.Threading.Monitor]::Enter($script:DevContextCacheLock)
    try {
        $script:DevContextCache[$key] = @{ CreatedAt = $now; Value = $value }
    }
    finally { [System.Threading.Monitor]::Exit($script:DevContextCacheLock) }
    return $value
}

function Clear-DevContextCache {
    [CmdletBinding()]
    param([string] $Provider)

    [System.Threading.Monitor]::Enter($script:DevContextCacheLock)
    try {
        if (-not $Provider) { $script:DevContextCache.Clear(); return }
        @($script:DevContextCache.Keys) |
            Where-Object { $_ -like "${Provider}:*" } |
            ForEach-Object { $script:DevContextCache.Remove($_) }
    }
    finally { [System.Threading.Monitor]::Exit($script:DevContextCacheLock) }
}

function ConvertTo-ReadOnlyDevContext {
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Collections.IDictionary] $InputObject)

    $dictionary = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($key in $InputObject.Keys) { $dictionary[[string]$key] = $InputObject[$key] }
    [System.Collections.ObjectModel.ReadOnlyDictionary[string, object]]::new($dictionary)
}
