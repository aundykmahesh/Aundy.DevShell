function Invoke-ClaudeApi {
    Remove-Item Env:ANTHROPIC_BASE_URL -ErrorAction SilentlyContinue
    Remove-Item Env:ANTHROPIC_AUTH_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC -ErrorAction SilentlyContinue

    if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_API_KEY_PERSONAL)) {
        Write-Warning 'ANTHROPIC_API_KEY_PERSONAL environment variable is not set.'
        Write-Information "Set it via: [System.Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY_PERSONAL', 'sk-ant-...', 'User')" -InformationAction Continue
        return
    }

    $env:ANTHROPIC_API_KEY = $env:ANTHROPIC_API_KEY_PERSONAL
    claude @args
}
