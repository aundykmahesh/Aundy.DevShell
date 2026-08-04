try {
    Import-Module Aundy.DevShell -DisableNameChecking -ErrorAction Stop
    $global:AundyDevShellPromptHostActivator = {
        param($Theme, $Context)
        $ohMyPosh = Get-Command -Name oh-my-posh -ErrorAction Ignore
        if (-not $ohMyPosh -or -not $Theme) { return }
        & $ohMyPosh.Source init pwsh --config $Theme.FullName | Invoke-Expression
        Aundy.DevShell\Enable-DevShellPromptRefresh -Context $Context -CaptureCurrentPrompt
    }
    $initialization = Initialize-DevShellProfile
    if ($initialization) {
        $null = & $global:AundyDevShellPromptHostActivator $initialization.Theme $initialization.Context
    }
}
catch {
    Write-Verbose "Unable to initialize Aundy.DevShell: $($_.Exception.Message)"
}
