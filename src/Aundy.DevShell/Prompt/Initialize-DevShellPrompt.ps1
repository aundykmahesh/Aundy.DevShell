function Initialize-DevShellPrompt {
    [CmdletBinding()]
    param()

    try {
        $ohMyPosh = Get-Command -Name oh-my-posh -ErrorAction SilentlyContinue
        if (-not $ohMyPosh) {
            return
        }

        $theme = New-DevShellPromptTheme
        if (-not $theme) {
            return
        }

        & $ohMyPosh.Source init pwsh --config $theme.FullName | Invoke-Expression
    }
    catch {
        Write-Verbose "Unable to initialize the DevShell prompt: $($_.Exception.Message)"
    }
}
