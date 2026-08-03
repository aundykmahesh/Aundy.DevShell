function Initialize-DevShellProfile {

    [CmdletBinding()]
    param()

    $ErrorActionPreference = 'Stop'

    try {

        Write-Host "[1] Loading settings"

        $settings = Get-Settings

        Write-Host "[2] Importing modules"

        foreach ($modulePath in $settings.Profile.ModulePaths) {
            if (Test-Path $modulePath) {
                Import-Module $modulePath -ErrorAction Stop
            }
        }

        Write-Host "[3] Terminal Icons"

        if (Get-Module -ListAvailable Terminal-Icons) {
            Import-Module Terminal-Icons
        }

        Write-Host "[4] PSReadLine"

        if ($Host.Name -eq 'ConsoleHost') {
            Import-Module PSReadLine -ErrorAction SilentlyContinue

            Set-PSReadLineOption -PredictionSource History
            Set-PSReadLineOption -EditMode Windows
        }

    }
    catch {

        Write-Host ""
        Write-Host "PROFILE FAILED" -ForegroundColor Red
        $_ | Format-List * -Force

        throw

    }

}