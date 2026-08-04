$script:PowerShellContextProvider = @{
    Name = 'PowerShell'; TimeToLive = [timespan]::Zero; RefreshPolicy = 'Always'
    CacheKey = { 'Default' }; Command = { Get-PowerShellContext }
    Default = [ordered]@{ Version = $null; Edition = $null; LanguageMode = $null; CurrentDirectory = $null }
}

function Get-PowerShellContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    ConvertTo-ImmutableDevContextObject -InputObject ([ordered]@{
        Version = $PSVersionTable.PSVersion.ToString()
        Edition = $PSVersionTable.PSEdition
        LanguageMode = $ExecutionContext.SessionState.LanguageMode.ToString()
        CurrentDirectory = (Get-Location).Path
    })
}
