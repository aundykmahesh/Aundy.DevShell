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

    $validStyles = @('Minimal', 'Developer', 'Cloud', 'AI', 'Presentation', 'Classic', 'Compact')
    if ($promptSettings.Style -notin $validStyles) {
        throw "Prompt style '$($promptSettings.Style)' is invalid. Valid styles: $($validStyles -join ', ')."
    }
    if ($promptSettings.LocationDisplay -notin 'Repository','Workspace') {
        throw "Prompt LocationDisplay '$($promptSettings.LocationDisplay)' is invalid. Valid values: Repository, Workspace."
    }

    $promptSettings
}
