try {
    Import-Module Aundy.DevShell -DisableNameChecking -ErrorAction Stop
    Initialize-DevShellProfile
}
catch {
    Write-Verbose "Unable to initialize Aundy.DevShell: $($_.Exception.Message)"
}
