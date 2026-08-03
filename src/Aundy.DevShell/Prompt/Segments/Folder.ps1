function New-FolderPromptSegment {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable] $Settings)

    try { [ordered]@{
        Name       = 'Folder'
        Type       = 'path'
        Template   = '{{ path .Path .Location }}'
        Foreground = $Settings.Colors.Folder
        Options    = [ordered]@{
            style                  = 'agnoster'
            folder_separator_icon = $Settings.Folder.Separator
            home_icon              = $Settings.Folder.HomeSymbol
            max_depth              = $Settings.Folder.MaxDepth
            mapped_locations       = $Settings.Folder.MappedLocations
        }
    } } catch { return $null }
}
