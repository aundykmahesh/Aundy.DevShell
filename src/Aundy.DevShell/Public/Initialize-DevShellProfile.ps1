function Initialize-DevShellProfile {
    [CmdletBinding()]
    param()

    try {
        $settings = Get-Settings
    }
    catch {
        Write-Verbose "Unable to load DevShell settings: $($_.Exception.Message)"
        return
    }

    foreach ($modulePath in $settings.Profile.ModulePaths) {
        try {
            if (Test-Path -LiteralPath $modulePath) {
                Import-Module -Name $modulePath -ErrorAction Stop
            }
        }
        catch {
            Write-Verbose "Unable to import optional module '$modulePath': $($_.Exception.Message)"
        }
    }

    try {
        if (Get-Module -ListAvailable -Name Terminal-Icons) {
            Import-Module -Name Terminal-Icons -ErrorAction Stop
        }
    }
    catch {
        Write-Verbose "Unable to initialize Terminal-Icons: $($_.Exception.Message)"
    }

    if ($Host.Name -eq 'ConsoleHost') {
        try {
            Import-Module -Name PSReadLine -ErrorAction Stop
            Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
            Set-PSReadLineOption -EditMode Windows -ErrorAction Stop
        }
        catch {
            Write-Verbose "Unable to configure PSReadLine: $($_.Exception.Message)"
        }
    }

    try {
        $context = Get-DevContext
        $theme = Initialize-DevShellPrompt -Context $context
        if ($theme) { [pscustomobject]@{ Theme=$theme; Context=$context } }
    }
    catch { Write-Verbose "Unable to prepare the DevShell prompt: $($_.Exception.Message)" }
}
