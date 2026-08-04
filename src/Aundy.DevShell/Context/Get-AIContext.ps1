$script:AIContextProvider = @{
    Name = 'AI'; TimeToLive = [timespan]::FromSeconds(10); RefreshPolicy = 'OnExpiry'
    CacheKey = { 'Default' }; Command = { Get-AIContext }
    Default = [ordered]@{ RuntimeAvailable = $false; OllamaRunning = $false; OpenWebUIRunning = $false; CloudflareTunnelRunning = $false }
}

function Get-AIContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $runtimeCommand = Get-Command -Name Get-AIOllamaStatus -ErrorAction Ignore
    $ollamaCommand = Get-Command -Name ollama -ErrorAction Ignore
    $ollamaProcess = Get-Process -Name ollama -ErrorAction Ignore
    $openWebUIProcess = Get-Process -Name 'open-webui' -ErrorAction Ignore
    $cloudflareProcess = Get-Process -Name cloudflared -ErrorAction Ignore

    ConvertTo-ImmutableDevContextObject -InputObject ([ordered]@{
        RuntimeAvailable = [bool]($runtimeCommand -or $ollamaCommand)
        OllamaRunning = [bool]$ollamaProcess
        OpenWebUIRunning = [bool]$openWebUIProcess
        CloudflareTunnelRunning = [bool]$cloudflareProcess
    })
}
