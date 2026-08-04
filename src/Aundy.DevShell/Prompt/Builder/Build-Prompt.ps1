function Build-Prompt {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][hashtable] $Settings,
        [Parameter(Mandatory)] $Context
    )

    Initialize-DevShellPromptRegistry -Settings $Settings
    $style = Get-DevShellPromptStyleDefinition -Name $Settings.Style
    $model = [ordered]@{
        Style = $style.Name
        Left = [System.Collections.Generic.List[object]]::new()
        Right = [System.Collections.Generic.List[object]]::new()
        Transient = [System.Collections.Generic.List[object]]::new()
        Secondary = [System.Collections.Generic.List[object]]::new()
    }

    foreach ($area in @('Left', 'Right', 'Transient', 'Secondary')) {
        $names = @($style[$area])
        $segments = foreach ($name in $names) {
            $segment = $script:PromptSegmentRegistry[$name]
            if ($null -eq $segment -or -not $segment.Enabled) { continue }
            $visible = [bool](& $segment.Visible $Context)
            $rendered = if ($visible) { & $segment.Render $Context } else { $null }
            $record = [ordered]@{
                Name = $segment.Name; Enabled = $segment.Enabled; Visible = [bool]($visible -and $rendered)
                Order = $segment.Order; Priority = $segment.Priority; Text = $rendered; Style = $segment.Style
            }
            Write-Output -InputObject $record -NoEnumerate
        }
        foreach ($segment in @($segments | Sort-Object Order, @{ Expression = 'Priority'; Descending = $true })) {
            [void]$model[$area].Add($segment)
        }
    }
    $model
}
