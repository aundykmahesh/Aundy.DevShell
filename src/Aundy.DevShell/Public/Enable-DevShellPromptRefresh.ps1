function Enable-DevShellPromptRefresh {
    <# .SYNOPSIS Connects the context refresh manager to an initialized host prompt. #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'The host-owned Oh My Posh delegate must survive Aundy.DevShell module replacement.')]
    [CmdletBinding()]
    param(
        $Context,
        [switch]$CaptureCurrentPrompt
    )

    Update-DevShellPromptContext -Context $Context | Out-Null
    if ($CaptureCurrentPrompt) {
        $promptCommand = Get-Command -Name prompt -CommandType Function -ErrorAction Ignore
        if (-not $promptCommand) { return }
        $global:AundyDevShellOhMyPoshPrompt = $promptCommand.ScriptBlock
    }
    $basePrompt = Get-Variable -Name AundyDevShellOhMyPoshPrompt -Scope Global -ValueOnly -ErrorAction Ignore
    if (-not $basePrompt) { return }

    $refresh = { Update-DevShellPromptContext | Out-Null }
    $wrapper = {
        try { & $refresh } catch { Write-Verbose "Prompt context refresh failed: $($_.Exception.Message)" }
        & $global:AundyDevShellOhMyPoshPrompt
    }.GetNewClosure()
    Set-Item -LiteralPath Function:\global:prompt -Value $wrapper -Force
}
