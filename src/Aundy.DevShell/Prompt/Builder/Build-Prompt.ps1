function Build-Prompt {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable] $Settings)

    $segments = @{}
    $addSegment = {
        param([string] $Name, [scriptblock] $Factory)
        try {
            $segment = & $Factory
            if ($null -ne $segment) { $segments[$Name] = $segment }
        }
        catch {
            # Optional prompt segments must never prevent the prompt from rendering.
        }
    }
    if ($Settings.ShowTime) { & $addSegment Time { New-TimePromptSegment -Settings $Settings } }
    if ($Settings.ShowFolder) { & $addSegment Folder { New-FolderPromptSegment -Settings $Settings } }
    if ($Settings.ShowGit) { & $addSegment Git { New-GitPromptSegment -Settings $Settings } }
    if ($Settings.ShowAzure) { & $addSegment Azure { New-AzurePromptSegment -Settings $Settings } }
    if ($Settings.ShowErrors) { & $addSegment Error { New-ErrorPromptSegment -Settings $Settings } }

    try {
        $promptCharacter = @{
            Name       = 'Prompt'
            Type       = 'text'
            Template   = $Settings.PromptCharacter
            Foreground = $Settings.Colors.Prompt
            Options    = @{}
        }
    }
    catch {
        $promptCharacter = $null
    }

    $newLine = {
        $line = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $args) {
            if ($null -ne $item) { [void] $line.Add($item) }
        }
        Write-Output -InputObject $line -NoEnumerate
    }
    $left = [System.Collections.Generic.List[object]]::new()
    $right = [System.Collections.Generic.List[object]]::new()

    switch ($Settings.Style) {
        'Classic' {
            [void] $left.Add((& $newLine $segments['Time'] $segments['Folder'] $segments['Git'] $segments['Azure'] $segments['Error']))
            [void] $left.Add((& $newLine $promptCharacter))
        }
        'Compact' {
            [void] $left.Add((& $newLine $segments['Folder'] $segments['Git'] $segments['Error']))
            [void] $left.Add((& $newLine $promptCharacter))
            [void] $right.Add((& $newLine $segments['Time'] $segments['Azure']))
        }
        'Minimal' {
            [void] $left.Add((& $newLine $segments['Time'] $segments['Azure']))
            [void] $left.Add((& $newLine $segments['Folder']))
            [void] $left.Add((& $newLine $segments['Git']))
            [void] $left.Add((& $newLine $segments['Error']))
            [void] $left.Add((& $newLine $promptCharacter))
        }
    }

    @{
        Style     = $Settings.Style
        Separator = $Settings.Separator
        Left      = $left
        Right     = $right
    }
}
