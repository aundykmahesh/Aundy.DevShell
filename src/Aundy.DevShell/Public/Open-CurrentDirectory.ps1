function Open-CurrentDirectory {
    <#
    .SYNOPSIS
    Opens the current directory in the platform file browser.
    .DESCRIPTION
    Invokes the operating system's default directory browser for the current location.
    .EXAMPLE
    Open-CurrentDirectory
    .OUTPUTS
    None.
    .NOTES
    A desktop session is required.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $path = (Get-Location).ProviderPath
    if ($PSCmdlet.ShouldProcess($path, 'Open in the platform file browser')) {
        if ($IsWindows) { Start-Process -FilePath 'explorer.exe' -ArgumentList $path }
        elseif ($IsMacOS) { Start-Process -FilePath 'open' -ArgumentList $path }
        else { Start-Process -FilePath 'xdg-open' -ArgumentList $path }
    }
}
