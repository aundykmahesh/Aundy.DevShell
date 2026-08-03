function Test-Administrator {
    <#
    .SYNOPSIS
    Tests whether the current PowerShell process has administrator privileges.
    .DESCRIPTION
    Returns true when running elevated on Windows. Other platforms currently return false.
    .EXAMPLE
    Test-Administrator
    .OUTPUTS
    System.Boolean
    .NOTES
    This function does not attempt to elevate the current process.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Test-IsAdministrator
}
