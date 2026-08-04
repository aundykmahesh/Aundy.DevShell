function Get-DevShellGlobalJsonSignature {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $globalJson = Find-DevContextGlobalJson -StartPath $Path
    if (-not $globalJson) { return '' }
    $item = Get-Item -LiteralPath $globalJson -ErrorAction Ignore
    if (-not $item) { return '' }
    '{0}|{1}|{2}' -f $item.FullName, $item.LastWriteTimeUtc.Ticks, $item.Length
}

function Update-DevShellPromptContext {
    <# Coordinates context invalidation and rendering; Prompt Engine owns neither. #>
    [CmdletBinding()]
    param($Context)

    $location = (Get-Location).Path
    $locationChanged = $null -ne $script:PromptRefreshLocation -and $script:PromptRefreshLocation -ne $location
    $globalJsonSignature = Get-DevShellGlobalJsonSignature -Path $location
    $globalJsonChanged = $null -ne $script:PromptRefreshGlobalJsonSignature -and `
        $script:PromptRefreshGlobalJsonSignature -ne $globalJsonSignature

    if ($locationChanged) { Clear-LocationSensitiveDevContextCache }
    elseif ($globalJsonChanged) { Clear-DevContextCache -Provider DotNet }

    $script:PromptRefreshLocation = $location
    $script:PromptRefreshGlobalJsonSignature = $globalJsonSignature
    $refreshDue = [datetime]::UtcNow -ge $script:PromptRefreshNextUtc
    if ($null -eq $Context -and -not $locationChanged -and -not $globalJsonChanged -and `
        $null -ne $script:PromptRefreshLastContext -and -not $refreshDue) {
        return $script:PromptRefreshLastContext
    }
    if ($null -eq $Context -or $locationChanged -or $globalJsonChanged) { $Context = Get-DevContext }
    $script:PromptRefreshLastContext = $Context

    $providerTtls = if ($null -ne $Context) {
        foreach ($property in $Context.PSObject.Properties) {
            $provider = $property.Value
            if ($null -eq $provider) { continue }
            $ttlProperty = $provider.PSObject.Properties['TTLSeconds']
            if ($ttlProperty -and $ttlProperty.Value -gt 0) { [double]$ttlProperty.Value }
        }
    }
    $ttlSeconds = if (@($providerTtls).Count) { ($providerTtls | Measure-Object -Minimum).Minimum } else { $null }
    $script:PromptRefreshNextUtc = if ($ttlSeconds) { [datetime]::UtcNow.AddSeconds($ttlSeconds) } else { [datetime]::UtcNow }

    $model = Get-DevShellPrompt -Context $Context
    $knownKeys = foreach ($name in $script:PromptSegmentRegistry.Keys) { "AUNDY_PROMPT_$($name.ToUpperInvariant())" }
    foreach ($key in $knownKeys) { [Environment]::SetEnvironmentVariable($key, $null, 'Process') }
    foreach ($area in 'Left','Right','Transient','Secondary') {
        $first = $true
        foreach ($segment in $model[$area]) {
            if (-not $segment.Visible) { continue }
            $value = [string]$segment.Text
            if (-not $first) { $value = " │ $value" }
            [Environment]::SetEnvironmentVariable("AUNDY_PROMPT_$($segment.Name.ToUpperInvariant())", $value, 'Process')
            $first = $false
        }
    }
    $Context
}
