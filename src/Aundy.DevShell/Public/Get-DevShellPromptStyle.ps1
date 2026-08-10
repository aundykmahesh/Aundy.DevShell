function Get-DevShellPromptStyle {
    <# .SYNOPSIS Returns metadata for the currently active prompt style. #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $settings = Get-DevShellPromptSettings
    $style = Get-DevShellPromptStyleDefinition -Name $settings.Style
    [pscustomobject][ordered]@{
        Name        = $style.Name
        Theme       = $style.Theme
        Renderer    = 'Oh My Posh'
        Description = $style.Description
        Category    = $style.Category
        IsDefault   = $style.IsDefault
        Enabled     = $style.Enabled
    }
}
