function Get-DevShellPromptSettings {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    if (-not $script:PromptSettingsCache) {
        $settings = Get-Settings
        if (-not $settings.ContainsKey('Prompt')) { throw 'The Prompt section is missing from Aundy.DevShell settings.' }
        $script:PromptSettingsCache = $settings.Prompt.Clone()
    }
    $promptSettings = $script:PromptSettingsCache
    if ($script:PromptStyleOverride) {
        $promptSettings.Style = $script:PromptStyleOverride
    }

    if ($promptSettings.LocationDisplay -notin 'Repository','Workspace') {
        throw "Prompt LocationDisplay '$($promptSettings.LocationDisplay)' is invalid. Valid values: Repository, Workspace."
    }
    Initialize-DevShellPromptRegistry -Settings $promptSettings
    $style = Get-DevShellPromptStyleDefinition -Name $promptSettings.Style
    if (-not $style.Enabled) { throw "Prompt style '$($promptSettings.Style)' is disabled." }
    $promptSettings.Style = $style.Name

    $promptSettings
}
