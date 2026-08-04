function Build-Theme {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable] $Prompt)

    $blocks = [System.Collections.Generic.List[object]]::new()
    $lineNumber = 0
    foreach ($line in $Prompt.Left) {
        $validSegments = @($line | Where-Object { $null -ne $_ })
        if ($validSegments.Count -eq 0) { continue }
        $renderedSegments = [System.Collections.Generic.List[object]]::new()
        $segmentNumber = 0
        foreach ($segment in $validSegments) {
            $template = if ($segmentNumber -gt 0) {
                " $($Prompt.Separator) $($segment.Template)"
            }
            else { $segment.Template }
            $rendered = [ordered]@{
                type       = $segment.Type
                style      = 'plain'
                template   = $template
                foreground = $segment.Foreground
            }
            if ($segment.Options.Count -gt 0) { $rendered.options = $segment.Options }
            if ($segment.Contains('ForegroundTemplates')) {
                $rendered.foreground_templates = $segment.ForegroundTemplates
            }
            $renderedSegments.Add($rendered)
            $segmentNumber++
        }
        $block = [ordered]@{
            type      = 'prompt'
            alignment = 'left'
            segments  = @($renderedSegments)
        }
        if ($lineNumber -gt 0) { $block.newline = $true }
        $blocks.Add($block)
        $lineNumber++
    }

    foreach ($line in $Prompt.Right) {
        $validSegments = @($line | Where-Object { $null -ne $_ })
        if ($validSegments.Count -eq 0) { continue }
        $segments = foreach ($segment in $validSegments) {
            $rendered = [ordered]@{
                type       = $segment.Type
                style      = 'plain'
                template   = $segment.Template
                foreground = $segment.Foreground
            }
            if ($segment.Options.Count -gt 0) { $rendered.options = $segment.Options }
            $rendered
        }
        $blocks.Add([ordered]@{ type = 'rprompt'; segments = @($segments) })
    }

    [ordered]@{
        '$schema'  = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json'
        version    = 4
        async      = $false
        final_space = $true
        blocks     = @($blocks)
    }
}
