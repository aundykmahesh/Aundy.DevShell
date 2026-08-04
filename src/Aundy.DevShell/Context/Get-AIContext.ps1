$script:AIContextProvider = @{
    Name = 'AI'; TimeToLive = [timespan]::FromSeconds(10); RefreshPolicy = 'OnExpiry'
    CacheKey = { 'Default' }; Command = { Get-AIContext }
    Default = [ordered]@{ RuntimeAvailable = $false; OllamaRunning = $false; OpenWebUIRunning = $false; CloudflareTunnelRunning = $false }
}

function Get-AIContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $runtimeCommand = Get-Command -Name Get-AIOllamaStatus -ErrorAction SilentlyContinue
    $ollamaCommand = Get-Command -Name ollama -ErrorAction SilentlyContinue
    $ollamaProcess = Get-Process -Name ollama -ErrorAction SilentlyContinue
    $openWebUIProcess = Get-Process -Name 'open-webui' -ErrorAction SilentlyContinue
    $cloudflareProcess = Get-Process -Name cloudflared -ErrorAction SilentlyContinue

    ConvertTo-ImmutableDevContextObject -InputObject ([ordered]@{
        RuntimeAvailable = [bool]($runtimeCommand -or $ollamaCommand)
        OllamaRunning = [bool]$ollamaProcess
        OpenWebUIRunning = [bool]$openWebUIProcess
        CloudflareTunnelRunning = [bool]$cloudflareProcess
    })
}
