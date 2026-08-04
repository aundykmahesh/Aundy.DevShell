function Set-DevShellPromptStyle {
    <#
    .SYNOPSIS
    Selects and activates a declarative prompt style for the current session.
    .DESCRIPTION
    Updates the Prompt Engine session style, regenerates the generated theme, and
    asks the host integration to reload Oh My Posh. External process execution is
    intentionally kept here, outside the Prompt Engine.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Minimal','Developer','Cloud','AI','Presentation','Classic','Compact')]
        [string]$Style,

        [switch]$PassThru
    )

    $script:PromptStyleOverride = $Style
    $context = Get-DevContext
    $prompt = Get-DevShellPrompt -Context $context
    $theme = New-DevShellPromptTheme -Prompt $prompt -Force

    $ohMyPosh = Get-Command -Name oh-my-posh -ErrorAction SilentlyContinue
    if ($ohMyPosh -and $theme) {
        & $ohMyPosh.Source init pwsh --config $theme.FullName | Invoke-Expression
    }

    if ($PassThru) { $prompt }
}
