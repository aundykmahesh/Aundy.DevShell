function New-ErrorPromptSegment {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable] $Settings)

    try { [ordered]@{
        Name       = 'Error'
        Type       = 'status'
        Template   = "$($Settings.Symbols.Failed) Exit {{ .Code }}"
        Foreground = $Settings.Colors.Error
        Options    = [ordered]@{ always_enabled = $false }
    } } catch { return $null }
}
