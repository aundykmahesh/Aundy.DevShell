function New-TimePromptSegment {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable] $Settings)

    try { [ordered]@{
        Name       = 'Time'
        Type       = 'time'
        Template   = "{{ .CurrentDate | date `"$($Settings.TimeFormat)`" }}"
        Foreground = $Settings.Colors.Time
        Options    = [ordered]@{ time_format = $Settings.TimeFormat }
    } } catch { return $null }
}
