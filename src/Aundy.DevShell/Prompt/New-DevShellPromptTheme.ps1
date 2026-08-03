function New-DevShellPromptTheme {
    <#
    .SYNOPSIS
    Generates the Oh My Posh theme from a developer-shell prompt model.
    .DESCRIPTION
    Converts the backend-neutral prompt model into Oh My Posh schema version 4 JSON. Existing content is left untouched when the generated theme has not changed.
    .PARAMETER Prompt
    A prompt model returned by Get-DevShellPrompt.
    .PARAMETER Path
    An optional output path. Relative paths are resolved from the Aundy.DevShell module directory.
    .EXAMPLE
    New-DevShellPromptTheme
    .EXAMPLE
    Get-DevShellPrompt | New-DevShellPromptTheme -Path '../../themes/Aundy.omp.json'
    .OUTPUTS
    System.IO.FileInfo
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(ValueFromPipeline)]
        [hashtable] $Prompt,

        [string] $Path
    )

    process {
        if (-not $Prompt) { $Prompt = Get-DevShellPrompt }
        $themePath = Resolve-DevShellThemePath -Path $Path

        $theme = Build-Theme -Prompt $Prompt
        $json = $theme | ConvertTo-Json -Depth 20
        $null = $json | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        $existing = if (Test-Path -LiteralPath $themePath -PathType Leaf) {
            Get-Content -LiteralPath $themePath -Raw
        }
        else { $null }

        if ($existing -ne $json -and $PSCmdlet.ShouldProcess($themePath, 'Generate Oh My Posh theme')) {
            $parent = Split-Path -Path $themePath -Parent
            if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
                New-Item -Path $parent -ItemType Directory -Force | Out-Null
            }
            Set-Content -LiteralPath $themePath -Value $json -Encoding utf8NoBOM -NoNewline
        }

        if (Test-Path -LiteralPath $themePath -PathType Leaf) {
            Get-Item -LiteralPath $themePath
        }
    }
}
