function Show-DevShellPrompt {
    <# .SYNOPSIS Shows Prompt Engine visibility and generation diagnostics. #>
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline)]$Context)
    process {
        if ($null -eq $Context) { $Context = Get-DevContext }
        $prompt = Get-DevShellPrompt -Context $Context
        $all = @($prompt.Left) + @($prompt.Right) + @($prompt.Transient) + @($prompt.Secondary)
        $themePath = Resolve-DevShellThemePath
        $file = Get-Item -LiteralPath $themePath -ErrorAction SilentlyContinue
        [pscustomobject][ordered]@{
            'Prompt Style' = $prompt.Style
            Visible = @($all | Where-Object Visible | Select-Object -ExpandProperty Name -Unique)
            Hidden = @($all | Where-Object { -not $_.Visible } | Select-Object -ExpandProperty Name -Unique)
            Theme = $themePath
            'Last Generation Time' = if ($script:PromptLastGenerationTime) { $script:PromptLastGenerationTime } elseif ($file) { $file.LastWriteTime } else { $null }
        }
    }
}
