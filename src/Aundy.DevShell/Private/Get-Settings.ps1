function Get-Settings {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string] $Path
    )

    $settingsPath = Resolve-DevShellSettingsPath -Path $Path

    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
        throw "Aundy.DevShell settings file was not found at '$settingsPath'."
    }

    Import-PowerShellDataFile -LiteralPath $settingsPath
}
