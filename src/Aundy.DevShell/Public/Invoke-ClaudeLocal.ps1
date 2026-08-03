function Invoke-ClaudeLocal {
    Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
    $env:ANTHROPIC_BASE_URL = "http://localhost:11434"
    $env:ANTHROPIC_AUTH_TOKEN = "ollama"
    $env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
    claude @args
}
