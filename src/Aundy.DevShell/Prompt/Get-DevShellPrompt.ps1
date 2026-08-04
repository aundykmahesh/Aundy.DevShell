function Get-DevShellPrompt {
    <# .SYNOPSIS Builds a backend-neutral PromptModel solely from DevContext. #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(ValueFromPipeline)] $Context)
    process {
        if ($null -eq $Context) { $Context = Get-DevContext }
        Build-Prompt -Settings (Get-DevShellPromptSettings) -Context $Context
    }
}
