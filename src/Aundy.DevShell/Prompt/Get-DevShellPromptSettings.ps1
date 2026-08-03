function Get-DevShellPromptSettings {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $settings = Get-Settings
    if (-not $settings.ContainsKey('Prompt')) {
        throw 'The Prompt section is missing from Aundy.DevShell settings.'
    }

    $promptSettings = $settings.Prompt.Clone()
    if ($script:PromptStyleOverride) {
        $promptSettings.Style = $script:PromptStyleOverride
    }

    $validStyles = @('Classic', 'Compact', 'Minimal')
    if ($promptSettings.Style -notin $validStyles) {
        throw "Prompt style '$($promptSettings.Style)' is invalid. Valid styles: $($validStyles -join ', ')."
    }

    $promptSettings
}
