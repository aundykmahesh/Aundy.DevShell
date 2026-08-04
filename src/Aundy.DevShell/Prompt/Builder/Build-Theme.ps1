function Build-Theme {
    <# Oh My Posh renderer. It knows only PromptModel, never DevContext or providers. #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable]$Prompt)
    $blocks = [System.Collections.Generic.List[object]]::new()
    foreach ($area in @('Left','Right','Secondary')) {
        $registered = @(if ($Prompt.Contains($area)) { $Prompt[$area] | Where-Object { $null -ne $_ -and $_.Enabled } })
        if ($registered.Count -eq 0) { continue }
        $segments = foreach ($segment in $registered) {
            [ordered]@{
                type = $segment.Style.Type
                style = 'plain'
                foreground = $segment.Style.Foreground
                template = "{{ .Env.AUNDY_PROMPT_$($segment.Name.ToUpperInvariant()) }}"
            }
        }
        [void]$blocks.Add([ordered]@{ type='prompt'; alignment=$area.ToLowerInvariant(); newline=$false; segments=@($segments) })
    }
    [ordered]@{
        '$schema'='https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json'
        version=4; async=$false; final_space=$true; blocks=@($blocks)
        transient_prompt = if ($Prompt.Contains('Transient') -and @($Prompt.Transient | Where-Object Visible).Count) { [ordered]@{ template=(@($Prompt.Transient | Where-Object Visible).Text -join ' ') } } else { $null }
    }
}
