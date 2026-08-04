$script:DevContextProviders = @(
    @{ Name = 'PowerShell'; Command = { Get-PowerShellContext }; TimeToLive = [timespan]::Zero; CacheKey = { 'Default' } }
    @{ Name = 'Git'; Command = { Get-GitContext }; TimeToLive = [timespan]::FromSeconds(2); CacheKey = { (Get-Location).Path } }
    @{ Name = 'Azure'; Command = { Get-AzureContext }; TimeToLive = [timespan]::FromSeconds(30); CacheKey = { 'Default' } }
    @{ Name = 'Docker'; Command = { Get-DockerContext }; TimeToLive = [timespan]::FromSeconds(10); CacheKey = { 'Default' } }
    @{ Name = 'DotNet'; Command = { Get-DotNetContext }; TimeToLive = [timespan]::FromMinutes(5); CacheKey = { 'Default' } }
)

function Get-DevContext {
    <#
    .SYNOPSIS
    Returns a cached, read-only snapshot of the current developer environment.
    #>
    [CmdletBinding()]
    param()

    $values = [ordered]@{
        PowerShellVersion = $null; Administrator = $false; CurrentDirectory = (Get-Location).Path
        Repository = $null; GitBranch = $null; GitDirty = $false; GitAhead = 0; GitBehind = 0
        AzureSubscription = $null; AzureTenant = $null; AzureEnvironment = $null
        DotNetVersion = $null; DockerRunning = $false; KubectlContext = $null
        CurrentUser = $null; ComputerName = $null; OperatingSystem = $null; AIRuntimeAvailable = $false
    }
    $failures = [System.Collections.Generic.List[string]]::new()

    foreach ($registration in $script:DevContextProviders) {
        try {
            $provider = $registration.Command
            $cacheKey = & $registration.CacheKey
            $providerResult = Get-CachedDevContextProvider -Name $registration.Name -TimeToLive $registration.TimeToLive -Provider $provider -CacheKey $cacheKey
            if ($null -eq $providerResult) { continue }
            foreach ($property in $providerResult.PSObject.Properties) {
                if ($values.Contains($property.Name)) { $values[$property.Name] = $property.Value }
            }
        }
        catch { $failures.Add(('{0}: {1}' -f $registration.Name, $_.Exception.Message)) }
    }

    $values.ProviderFailures = [System.Collections.ObjectModel.ReadOnlyCollection[string]]::new($failures)
    ConvertTo-ReadOnlyDevContext -InputObject $values
}
