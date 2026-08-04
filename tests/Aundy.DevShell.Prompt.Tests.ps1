BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1'
    Import-Module $manifestPath -Force
}

Describe 'Aundy.DevShell Prompt Engine' {
    BeforeEach {
        InModuleScope Aundy.DevShell {
            $script:AzurePromptContextChecked = $false
            $script:AzurePromptContext = $null
        }
        Set-DevShellPromptStyle -Style Minimal | Out-Null
    }

    It 'loads configuration-driven prompt settings' {
        $settings = Get-DevShellSettings
        $settings.Prompt.Style | Should -Be 'Minimal'
        $settings.Prompt.ShowTime | Should -BeTrue
        $settings.Prompt.ShowFolder | Should -BeTrue
        $settings.Prompt.AzureAliases['BOQ Group Non-Prod Sub 1'] | Should -Be 'BOQ NonProd'
    }

    It 'builds a backend-neutral prompt model before JSON' {
        $prompt = Get-DevShellPrompt
        $prompt | Should -BeOfType ([hashtable])
        $prompt.Keys | Should -Contain 'Left'
        $prompt.Keys | Should -Contain 'Right'
        $prompt.Left[0].Name | Should -Be @('Time', 'Azure')
        $prompt.Left[-1].Name | Should -Be 'Prompt'
    }

    It 'changes layout without changing reusable segments' {
        $minimal = Set-DevShellPromptStyle -Style Minimal
        $classic = Set-DevShellPromptStyle -Style Classic
        $compact = Set-DevShellPromptStyle -Style Compact

        $minimal.Style | Should -Be 'Minimal'
        $classic.Style | Should -Be 'Classic'
        $compact.Style | Should -Be 'Compact'
        @($compact.Right[0]).Name | Should -Be @('Time', 'Azure')
        @($classic.Left[0]).Name | Should -Contain 'Git'
    }

    It 'creates conditional Git, Azure, and error segments' {
        $prompt = Get-DevShellPrompt
        $allSegments = @($prompt.Left | ForEach-Object { $_ })
        $git = $allSegments | Where-Object Name -eq 'Git'
        $azure = $allSegments | Where-Object Name -eq 'Azure'
        $errorSegment = $allSegments | Where-Object Name -eq 'Error'

        $git.Options.fetch_status | Should -BeTrue
        $git.Options.source | Should -Be 'cli'
        $git.Template | Should -Match 'Unmerged'
        $git.Template | Should -Not -Match 'Ahead|Behind|Stash'
        $azure.Template | Should -Match 'BOQ NonProd'
        $azure.Template | Should -Match '\.Name'
        $azure.Template | Should -Not -Match 'EnvironmentName|Tenant|\.ID'
        $azure.Options.source | Should -Be 'cli|pwsh'
        $azure.Template | Should -Not -Match '[0-9a-f]{8}-[0-9a-f]{4}'
        $errorSegment.Options.always_enabled | Should -BeFalse
    }

    It 'omits unavailable dependency-backed segments without throwing' {
        InModuleScope Aundy.DevShell {
            $script:AzurePromptContextChecked = $false
            $script:AzurePromptContext = $null
            Mock Get-Command { $null } -ParameterFilter { $Name -in @('Get-AzContext', 'az', 'git') }

            { $prompt = Get-DevShellPrompt } | Should -Not -Throw
            $names = @(Get-DevShellPrompt).Left | ForEach-Object { $_ } | ForEach-Object Name
            $names | Should -Not -Contain 'Azure'
            $names | Should -Not -Contain 'Git'
            $names | Should -Contain 'Prompt'
        }
    }

    It 'isolates a terminating segment failure from the prompt builder' {
        InModuleScope Aundy.DevShell {
            Mock New-TimePromptSegment { throw 'time dependency failed' }

            { $prompt = Get-DevShellPrompt } | Should -Not -Throw
            $names = @(Get-DevShellPrompt).Left | ForEach-Object { $_ } | ForEach-Object Name
            $names | Should -Not -Contain 'Time'
            $names | Should -Contain 'Prompt'
        }
    }

    It 'falls back to Azure CLI when Get-AzContext fails' {
        InModuleScope Aundy.DevShell {
            function script:Get-AzContext { throw 'Az.Accounts unavailable' }
            function script:az { $global:LASTEXITCODE = 0; '{"name":"CLI Subscription"}' }
            try {
                $context = Get-DevShellAzureContext
                $context.Provider | Should -Be 'Azure CLI'
                $context.Subscription | Should -Be 'CLI Subscription'
            }
            finally {
                Remove-Item Function:\Get-AzContext, Function:\az -ErrorAction SilentlyContinue
            }
        }
    }

    It 'ignores null segments while rendering a theme' {
        InModuleScope Aundy.DevShell {
            $prompt = @{
                Style = 'Minimal'; Separator = '|'
                Left = @(@($null, @{ Name = 'Prompt'; Type = 'text'; Template = '>'; Foreground = '#fff'; Options = @{} }))
                Right = @()
            }
            { Build-Theme -Prompt $prompt } | Should -Not -Throw
            $theme = Build-Theme -Prompt $prompt
            $theme.blocks[0].segments.Count | Should -Be 1
        }
    }

    It 'configures portable, abbreviated folder rendering' {
        $prompt = Get-DevShellPrompt
        $folder = @($prompt.Left | ForEach-Object { $_ }) | Where-Object Name -eq 'Folder'

        $folder.Options.style | Should -Be 'agnoster'
        $folder.Options.max_depth | Should -Be 2
        $folder.Options.folder_separator_icon | Should -Be '/'
        $folder.Options.mapped_locations['C:/Users/Mahesh'] | Should -Be '~'
        $folder.Options.mapped_locations['C:/Git'] | Should -Be ''
    }

    It 'generates valid schema-version-four theme JSON' {
        $path = Join-Path $TestDrive 'Aundy.omp.json'
        $file = New-DevShellPromptTheme -Path $path
        $theme = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json -AsHashtable

        $theme.version | Should -Be 4
        $theme.async | Should -BeFalse
        $theme.blocks.Count | Should -BeGreaterThan 0
        $theme.blocks[0].segments[0].type | Should -Be 'time'
        $theme.blocks[0].segments.Count | Should -Be 2
        $theme.blocks[0].segments[1].template | Should -Match '^ │ ☁'
    }

    It 'builds a warmed prompt model in under 20 milliseconds' {
        Get-DevShellPrompt | Out-Null
        $elapsed = (Measure-Command { Get-DevShellPrompt | Out-Null }).TotalMilliseconds
        $elapsed | Should -BeLessThan 20
    }

    It 'reloads the module and regenerates the theme without installing a prompt' {
        InModuleScope Aundy.DevShell {
            Mock Remove-Module
            Mock Import-Module
            Mock New-DevShellPromptTheme

            Reload-Profile 6>$null

            Should -Invoke Remove-Module -Times 1 -Exactly
            Should -Invoke Import-Module -Times 1 -Exactly
            Should -Invoke New-DevShellPromptTheme -Times 1 -Exactly
        }
    }

    It 'returns diagnostics only when explicitly requested' {
        InModuleScope Aundy.DevShell {
            Mock Get-DevShellAzureContext { [pscustomobject]@{ Connected = $false; Provider = $null; Subscription = $null } }
            Mock Get-DevShellGitContext { [pscustomobject]@{ Repository = $false; Branch = $null; State = 'Outside repository' } }
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'oh-my-posh' }

            $diagnostics = Show-DevShellDiagnostics
            $diagnostics.AzureStatus | Should -Be 'Disconnected'
            $diagnostics.GitStatus | Should -Be 'Outside repository'
            $diagnostics.PromptStyle | Should -BeIn @('Classic', 'Compact', 'Minimal')
            $diagnostics.SettingsFile | Should -Match 'Settings\.psd1$'
        }
    }
}
