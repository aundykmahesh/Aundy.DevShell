BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1'
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
            'Get-DevShellPrompt'
            'New-DevShellPromptTheme'
            'Set-DevShellPromptStyle'
        ) | Sort-Object
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

    It 'keeps prompt installation in the PowerShell profile' {
        $profilePath = Join-Path $PSScriptRoot '../profile/Microsoft.PowerShell_profile.ps1'
        $profile = Get-Content -LiteralPath $profilePath -Raw
        $moduleScripts = Get-ChildItem (Join-Path $PSScriptRoot '../src/Aundy.DevShell') -Filter '*.ps1' -Recurse |
            Get-Content -Raw

        $profile | Should -Match 'New-DevShellPromptTheme'
        $profile | Should -Match 'oh-my-posh\s+init\s+pwsh\s+--config'
        $profile | Should -Match 'Invoke-Expression'
        $moduleScripts | Should -Not -Match 'oh-my-posh\s+init'
        $moduleScripts | Should -Not -Match 'Invoke-Expression'
    }

    It 'keeps profile initialization free of diagnostic output' {
        $initializerPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Public/Initialize-DevShellProfile.ps1'
        $initializer = Get-Content -LiteralPath $initializerPath -Raw
        $initializer | Should -Not -Match 'Write-Information'
        $initializer | Should -Not -Match 'dotnet\s+--list-sdks'
        $initializer | Should -Not -Match 'LanguageMode'
    }
}
