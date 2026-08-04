function Set-DevShellPromptStyle {
    <# .SYNOPSIS Selects a declarative prompt style and regenerates its theme. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateSet('Minimal','Developer','Cloud','AI','Presentation','Classic','Compact')][string]$Style)
    $script:PromptStyleOverride = $Style
    $prompt = Get-DevShellPrompt
    New-DevShellPromptTheme -Prompt $prompt -Force | Out-Null
    $prompt
}
