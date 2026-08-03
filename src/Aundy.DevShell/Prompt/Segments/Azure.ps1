function New-AzurePromptSegment {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable] $Settings)

    try {
        if (-not $script:AzurePromptContextChecked) {
            $script:AzurePromptContext = Get-DevShellAzureContext
            $script:AzurePromptContextChecked = $true
        }
        if (-not $script:AzurePromptContext) { return $null }

        $aliasNames = @($Settings.AzureAliases.Keys | Sort-Object)
        $conditions = foreach ($aliasName in $aliasNames) {
            $name = $aliasName.Replace('"', '\"')
            "{{ if eq .Name `"$name`" }}$($Settings.AzureAliases[$aliasName]){{ end }}"
        }
        $knownNames = @($aliasNames | ForEach-Object { "(eq .Name `"$($_.Replace('"', '\"'))`")" })
        $fallback = if ($knownNames.Count -gt 0) {
            "{{ if not (or $($knownNames -join ' ')) }}{{ .Name }}{{ end }}"
        }
        else { '{{ .Name }}' }

        [ordered]@{
            Name       = 'Azure'
            Type       = 'az'
            Template   = "$($Settings.Symbols.Azure) $($conditions -join '')$fallback"
            Foreground = $Settings.Colors.Azure
            Options    = [ordered]@{
                display_default = $false
                source          = 'cli|pwsh'
            }
        }
    }
    catch { return $null }
}
