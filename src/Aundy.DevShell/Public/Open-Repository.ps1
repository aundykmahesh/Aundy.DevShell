function Open-Repository {
    <#
    .SYNOPSIS
    Opens the configured repository in the preferred editor.
    .DESCRIPTION
    Reads RepositoryRoot and PreferredEditor from Aundy.DevShell settings and launches the editor.
    .PARAMETER Path
    Overrides the configured repository root.
    .EXAMPLE
    Open-Repository
    .EXAMPLE
    Open-Repository -Path C:\Git\Aundy.DevShell
    .OUTPUTS
    None.
    .NOTES
    RepositoryRoot must be configured when Path is omitted.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([string] $Path)

    $settings = Get-Settings
    $repositoryPath = if ($Path) { $Path } else { $settings.RepositoryRoot }
    if (-not $repositoryPath) {
        throw 'RepositoryRoot is not configured. Specify -Path or update Settings.psd1.'
    }
    if (-not (Test-Path -LiteralPath $repositoryPath -PathType Container)) {
        throw "Repository path '$repositoryPath' does not exist."
    }
    if ($PSCmdlet.ShouldProcess($repositoryPath, "Open with $($settings.PreferredEditor)")) {
        Start-Process -FilePath $settings.PreferredEditor -ArgumentList $repositoryPath
    }
}
