function Enter-DevShellWorkingDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    Set-DevLocation -Name $Name
}
