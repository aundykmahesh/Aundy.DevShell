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
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string]$Style,

        [switch]$PassThru,

        [Parameter(DontShow)][switch]$Restore
    )

    process {
        $null = Get-DevShellPromptSettings
        try { $definition = Get-DevShellPromptStyleDefinition -Name $Style }
        catch {
            $available = @(Get-DevShellPromptStyles | Select-Object -ExpandProperty Name)
            throw "Unknown prompt style '$Style'.`n`nAvailable styles`n`n$($available -join "`n")`n`nRun`n`nGet-DevShellPromptStyles"
        }
        if (-not $definition.Enabled) { throw "Prompt style '$($definition.Name)' is disabled." }

        $script:PromptStyleOverride = $definition.Name
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
}
