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

        [switch]$PassThru,

        [Parameter(DontShow)][switch]$Restore
    )

    $script:PromptStyleOverride = $Style
    $context = Get-DevContext
    $prompt = Get-DevShellPrompt -Context $context
    $theme = New-DevShellPromptTheme -Prompt $prompt -Force:(-not $Restore)
    if ($theme) {
        $hostActivator = Get-Variable -Name AundyDevShellPromptHostActivator -Scope Global -ValueOnly -ErrorAction Ignore
        if (-not $Restore -and $hostActivator) { & $hostActivator $theme $context }
        else { Enable-DevShellPromptRefresh -Context $context }
    }

    if ($PassThru) { $prompt }
}
