function Get-DevShellPromptStyles {
    <# .SYNOPSIS Returns every available prompt style registered by the Prompt Engine. #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $null = Get-DevShellPromptSettings
    $script:PromptStyleRegistry.Values |
        Where-Object Enabled |
        Sort-Object RegistrationOrder |
        ForEach-Object {
            [pscustomobject][ordered]@{
                Name        = $_.Name
                Description = $_.Description
                Category    = $_.Category
                IsDefault   = $_.IsDefault
                Theme       = $_.Theme
                Enabled     = $_.Enabled
            }
        }
}
