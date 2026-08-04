BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1'
    Remove-Module Aundy.DevShell -Force -ErrorAction SilentlyContinue
    Import-Module $manifestPath -Force
}

Describe 'Aundy.DevShell module' {
    It 'has a valid manifest' {
        { Test-ModuleManifest -Path $manifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'exports every migrated public script' {
        $expected = Get-ChildItem (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Public') -Filter '*.ps1' |
            Select-Object -ExpandProperty BaseName |
            Sort-Object
        $expected = @($expected) + @(
            'Get-DevContext'
            'Get-DevShellPrompt'
            'New-DevShellPromptTheme'
            'Set-DevShellPromptStyle'
            'Show-DevContext'
            'Show-DevShellPrompt'
        ) | Sort-Object -Unique
        $commands = (Get-Module Aundy.DevShell).ExportedFunctions.Keys | Sort-Object
        $commands | Should -Be $expected
    }

    It 'preserves profile aliases' {
        (Get-Alias reload).Definition | Should -Be 'Reload-Profile'
        (Get-Alias rshell).Definition | Should -Be 'Restart-Shell'
        (Get-Alias .code).Definition | Should -Be 'Open-Code'
        (Get-Alias .codecleanest).Definition | Should -Be 'CodeCleanest'
    }

    It 'loads default settings' {
        $settings = Get-DevShellSettings
        $settings.Endpoints.Ollama | Should -Be 'http://localhost:11434'
        $settings.Git.DefaultBranch | Should -Be 'main'
    }

    It 'loads settings from an explicit trusted data file' {
        $customPath = Join-Path $TestDrive 'Settings.psd1'
        Set-Content -LiteralPath $customPath -Value "@{ Marker = 'Custom' }"
        (Get-DevShellSettings -Path $customPath).Marker | Should -Be 'Custom'
    }

    It 'returns a boolean for administrator status' {
        (Test-Administrator).GetType() | Should -Be ([bool])
    }

    It 'keeps the profile as a small bootstrapper' {
        $profilePath = Join-Path $PSScriptRoot '../profile/Microsoft.PowerShell_profile.ps1'
        (Get-Content -LiteralPath $profilePath).Count | Should -BeLessThan 100
        (Select-String -LiteralPath $profilePath -Pattern '^\s*function\s+').Count | Should -Be 0
    }

    It 'keeps prompt installation in the private prompt initializer' {
        $profilePath = Join-Path $PSScriptRoot '../profile/Microsoft.PowerShell_profile.ps1'
        $profile = Get-Content -LiteralPath $profilePath -Raw

        $enginePath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Prompt/Initialize-DevShellPrompt.ps1'
        $hostPath = Join-Path $PSScriptRoot '../profile/Microsoft.PowerShell_profile.ps1'
        $initializerPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Public/Initialize-DevShellProfile.ps1'
        $engine = Get-Content -LiteralPath $enginePath -Raw
        $hostIntegration = Get-Content -LiteralPath $hostPath -Raw
        $initializer = Get-Content -LiteralPath $initializerPath -Raw

        $profile | Should -Match 'Initialize-DevShellProfile'
        $engine | Should -Match 'New-DevShellPromptTheme'
        $hostIntegration | Should -Match 'init\s+pwsh\s+--config'
        $hostIntegration | Should -Match 'Invoke-Expression'
        $engine | Should -Match 'function\s+Initialize-DevShellPrompt'
    }

    It 'keeps profile initialization free of diagnostic output' {
        $initializerPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Public/Initialize-DevShellProfile.ps1'
        $initializer = Get-Content -LiteralPath $initializerPath -Raw
        $initializer | Should -Not -Match 'Write-Information'
        $initializer | Should -Not -Match 'dotnet\s+--list-sdks'
        $initializer | Should -Not -Match 'LanguageMode'
        $initializer | Should -Not -Match 'Write-(Host|Debug)'
    }
}
