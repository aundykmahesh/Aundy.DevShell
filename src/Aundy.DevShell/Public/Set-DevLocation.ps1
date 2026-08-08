function Set-DevLocation {
    <#
    .SYNOPSIS Changes to a configured developer navigation location.
    .DESCRIPTION Resolves a named location through the Workspace Engine and changes location only when its configured folder exists.
    .PARAMETER Name Configured location name. The name can be supplied positionally.
    .PARAMETER PassThru Returns the resolved location after navigation.
    .EXAMPLE Set-DevLocation Repos
    .EXAMPLE Set-DevLocation -Name SharedDomain -WhatIf
    .OUTPUTS Aundy.DevShell.DevLocation when PassThru is specified.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Low')]
    param(
        [Parameter(Mandatory, Position=0)][string] $Name,
        [switch] $PassThru
    )
    $location = Get-DevLocationInternal -Name $Name
    if (-not (Test-Path -LiteralPath $location.Path -PathType Container)) {
        throw "Developer location '$($location.Name)' is configured as '$($location.Path)', but that folder does not exist. Update Navigation.Locations in Settings.psd1 or create it outside DevShell."
    }
    if ($PSCmdlet.ShouldProcess($location.Path, "Set developer location to '$($location.Name)'")) {
        Set-Location -LiteralPath $location.Path
        if ($PassThru) { $location }
    }
}
