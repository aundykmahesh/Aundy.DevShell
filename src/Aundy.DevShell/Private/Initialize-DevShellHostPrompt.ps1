function Initialize-DevShellHostPrompt {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'The interactive prompt function and its stable Oh My Posh delegate must survive module-scope replacement.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$Theme,
        $Context,
        [switch]$Reinitialize
    )

    Update-DevShellPromptContext -Context $Context | Out-Null
    $basePromptVariable = Get-Variable -Name AundyDevShellOhMyPoshPrompt -Scope Global -ErrorAction Ignore
    if ($Reinitialize -or -not $basePromptVariable.Value) {
        $ohMyPosh = Get-Command -Name oh-my-posh -ErrorAction Ignore
        if (-not $ohMyPosh) { return }
        & $ohMyPosh.Source init pwsh --config $Theme.FullName | Invoke-Expression
        $promptCommand = Get-Command -Name prompt -CommandType Function -ErrorAction Ignore
        if (-not $promptCommand) { return }
        $global:AundyDevShellOhMyPoshPrompt = $promptCommand.ScriptBlock
    }
    if (-not (Get-Variable -Name AundyDevShellOhMyPoshPrompt -Scope Global -ValueOnly -ErrorAction Ignore)) { return }

    $refresh = { Update-DevShellPromptContext | Out-Null }
    $wrapper = {
        try { & $refresh } catch { Write-Verbose "Prompt context refresh failed: $($_.Exception.Message)" }
        & $global:AundyDevShellOhMyPoshPrompt
    }.GetNewClosure()
    Set-Item -LiteralPath Function:\global:prompt -Value $wrapper -Force
}
