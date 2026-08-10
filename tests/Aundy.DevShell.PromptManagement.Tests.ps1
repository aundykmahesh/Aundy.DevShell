BeforeAll {
    Remove-Module Aundy.DevShell -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1') -Force
}

Describe 'Prompt management and style discovery' {
    BeforeEach { InModuleScope Aundy.DevShell { $script:PromptStyleOverride = 'Minimal' } }

    It 'returns every enabled registered style with metadata' {
        $styles = @(Get-DevShellPromptStyles)
        $styles.Name | Should -Contain 'Minimal'
        $styles.Name | Should -Contain 'Developer'
        $styles.Count | Should -BeGreaterThan 0
        $styles | ForEach-Object {
            $_.Description | Should -Not -BeNullOrEmpty
            $_.Category | Should -Not -BeNullOrEmpty
            $_.Theme | Should -Not -BeNullOrEmpty
            $_.Enabled | Should -BeTrue
        }
        ($styles | Group-Object Name | Where-Object Count -ne 1) | Should -BeNullOrEmpty
    }

    It 'uses the registry as the complete public style source' {
        InModuleScope Aundy.DevShell {
            $null = Get-DevShellPromptSettings
            @(Get-DevShellPromptStyles).Count | Should -Be $script:PromptStyleRegistry.Count
        }
    }

    It 'returns the active style and renderer metadata' {
        $style = Get-DevShellPromptStyle
        $style.Name | Should -Be 'Minimal'
        $style.Theme | Should -Be 'Aundy.omp.json'
        $style.Renderer | Should -Be 'Oh My Posh'
    }

    It 'accepts case-insensitive names and normalizes to the registered name' {
        InModuleScope Aundy.DevShell {
            Mock Get-DevContext { [pscustomobject]@{} }
            Mock Get-DevShellPrompt { @{ Style='Developer'; Left=@(); Right=@(); Transient=@(); Secondary=@() } }
            Mock New-DevShellPromptTheme { [System.IO.FileInfo]'TestDrive:/Aundy.omp.json' }
            Mock Enable-DevShellPromptRefresh
            Set-DevShellPromptStyle developer
            $script:PromptStyleOverride | Should -Be 'Developer'
        }
    }

    It 'accepts pipeline input by name and refreshes immediately' {
        InModuleScope Aundy.DevShell {
            Mock Get-DevContext { [pscustomobject]@{} }
            Mock Get-DevShellPrompt { @{ Style='Cloud'; Left=@(); Right=@(); Transient=@(); Secondary=@() } }
            Mock New-DevShellPromptTheme { [System.IO.FileInfo]'TestDrive:/Aundy.omp.json' }
            Mock Enable-DevShellPromptRefresh
            Mock Get-Variable { $null } -ParameterFilter { $Name -eq 'AundyDevShellPromptHostActivator' }
            [pscustomobject]@{ Name='Cloud' } | Set-DevShellPromptStyle
            $script:PromptStyleOverride | Should -Be 'Cloud'
            Should -Invoke Enable-DevShellPromptRefresh -Times 1 -Exactly
        }
    }

    It 'throws a friendly error and preserves configuration for an invalid style' {
        InModuleScope Aundy.DevShell {
            $script:PromptStyleOverride = 'Minimal'
            { Set-DevShellPromptStyle Banana } | Should -Throw "*Unknown prompt style 'Banana'.*Available styles*Get-DevShellPromptStyles*"
            $script:PromptStyleOverride | Should -Be 'Minimal'
        }
    }

    It 'reports prompt registry diagnostics' {
        $diagnostics = Show-DevShellDiagnostics
        $diagnostics.PromptStyle | Should -Be 'Minimal'
        $diagnostics.PromptRenderer | Should -Be 'Oh My Posh'
        $diagnostics.PromptTheme | Should -Be 'Aundy.omp.json'
        $diagnostics.PromptRegistryCount | Should -Be @(Get-DevShellPromptStyles).Count
    }

    It 'exposes prompt management through command discovery' {
        $promptCommands = @(Get-DevShellCommands | Where-Object Category -eq Prompt | Select-Object -ExpandProperty Name)
        foreach ($name in 'Get-DevShellPrompt','Get-DevShellPromptStyle','Get-DevShellPromptStyles','Set-DevShellPromptStyle') {
            $promptCommands | Should -Contain $name
        }
    }

    It 'does not hardcode style validation in public commands' {
        $setter = Get-Content (Join-Path $PSScriptRoot '../src/Aundy.DevShell/Public/Set-DevShellPromptStyle.ps1') -Raw
        $setter | Should -Not -Match 'ValidateSet'
    }
}
