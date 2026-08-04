function Initialize-DevShellPrompt {
    <# Builds/reuses the theme. Host integration is deliberately outside Prompt Engine. #>
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline)]$Context)
    process {
        if ($null -eq $Context) { $Context = Get-DevContext }
        New-DevShellPromptTheme -Prompt (Get-DevShellPrompt -Context $Context)
    }
}
