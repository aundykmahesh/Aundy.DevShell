function Set-DevShellPromptStyle {
    <#
    .SYNOPSIS
    Selects the prompt layout for the current PowerShell session.
    .DESCRIPTION
    Changes only the prompt layout. Segment configuration remains unchanged. The generated Oh My Posh theme is refreshed immediately.
    .PARAMETER Style
    The Classic, Compact, or Minimal prompt layout.
    .EXAMPLE
    Set-DevShellPromptStyle -Style Compact
    .OUTPUTS
    System.Collections.Hashtable
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Classic', 'Compact', 'Minimal')]
        [string] $Style
    )

    $script:PromptStyleOverride = $Style
    $prompt = Get-DevShellPrompt
    New-DevShellPromptTheme -Prompt $prompt | Out-Null
    $prompt
}
