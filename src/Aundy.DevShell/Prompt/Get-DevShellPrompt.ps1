function Get-DevShellPrompt {
    <#
    .SYNOPSIS
    Gets the configured developer-shell prompt model.
    .DESCRIPTION
    Builds a backend-neutral prompt model from the active settings and style. The model contains left and right segment lines and can be passed to New-DevShellPromptTheme.
    .EXAMPLE
    Get-DevShellPrompt
    .EXAMPLE
    Get-DevShellPrompt | New-DevShellPromptTheme
    .OUTPUTS
    System.Collections.Hashtable
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $settings = Get-DevShellPromptSettings
    Build-Prompt -Settings $settings
}
