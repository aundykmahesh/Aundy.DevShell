function Get-DevLocation {
    <#
    .SYNOPSIS Lists configured developer navigation locations.
    .DESCRIPTION Returns validated, structured locations from the Settings Engine without scanning the filesystem.
    .PARAMETER Name Selects an enabled location by exact, case-insensitive name.
    .PARAMETER Refresh Rebuilds the validated in-memory location registry.
    .EXAMPLE Get-DevLocation
    .EXAMPLE Get-DevLocation -Name CBI
    .OUTPUTS Aundy.DevShell.DevLocation
    #>
    [CmdletBinding()]
    param([string] $Name, [switch] $Refresh)
    if ($Name) { return Get-DevLocationInternal -Name $Name -Refresh:$Refresh }
    $registry = Initialize-DevLocationRegistry -Refresh:$Refresh
    @($registry.Values | Where-Object Enabled | Sort-Object Name)
}
