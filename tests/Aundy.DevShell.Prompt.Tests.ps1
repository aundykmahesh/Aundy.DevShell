BeforeAll {
    Remove-Module Aundy.DevShell -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1') -Force
}

Describe 'Prompt Engine v1 compatibility' {
    It 'retains Classic and Compact style names' {
        InModuleScope Aundy.DevShell {
            Initialize-DevShellPromptRegistry -Settings (Get-DevShellPromptSettings)
            (Get-DevShellPromptStyleDefinition Classic).Name | Should -Be 'Classic'
            (Get-DevShellPromptStyleDefinition Compact).Name | Should -Be 'Compact'
        }
    }

    It 'keeps prompt initialization isolated from the profile' {
        $initializer=Get-Content (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Prompt/Initialize-DevShellPrompt.ps1') -Raw
        $initializer | Should -Match 'New-DevShellPromptTheme'
        $initializer | Should -Not -Match 'Get-Command|Invoke-Expression|\&\s*oh-my-posh'
    }
}
