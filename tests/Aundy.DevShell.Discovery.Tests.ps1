BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Aundy.DevShell.psd1'
    Remove-Module Aundy.DevShell -Force -ErrorAction SilentlyContinue
    Import-Module $manifestPath -Force
}

Describe 'DevShell command discovery' {
    It 'registers every exported DevShell command exactly once' {
        $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
        $exported = @($manifest.FunctionsToExport | Sort-Object)
        $registered = @(Get-DevShellCommands |
            Where-Object Visibility -eq 'Public' |
            Select-Object -ExpandProperty Name |
            Sort-Object)

        foreach ($exportedCommand in $exported) {
            $registered | Should -Contain $exportedCommand
        }
        ($registered | Group-Object | Where-Object Count -ne 1) | Should -BeNullOrEmpty
    }

    It 'explicitly registers the AI.Aundy public command surface' {
        $aiCommands = @(Get-DevShellCommands |
            Where-Object { $_.Visibility -eq 'Public' -and $_.Category -eq 'AI' } |
            Select-Object -ExpandProperty Name)

        foreach ($commandName in @(
            'Install-AIOllamaService'
            'Install-AIOpenWebUIService'
            'Get-AICloudflareStatus'
            'Get-AIOllamaStatus'
            'Get-AIOpenWebUIStatus'
            'Get-AIRuntime'
        )) {
            $aiCommands | Should -Contain $commandName
        }
    }

    It 'exposes complete command metadata' {
        Get-DevShellCommands | ForEach-Object {
            $_.Name | Should -Not -BeNullOrEmpty
            $_.Category | Should -Not -BeNullOrEmpty
            $_.Summary | Should -Not -BeNullOrEmpty
            ($_.RelatedCommands -is [string[]]) | Should -BeTrue
            $_.Visibility | Should -BeIn @('Public', 'Internal')
        }
    }

    It 'groups registered commands by category in the overview' {
        $output = Show-DevShell | Out-String
        $output | Should -Match 'Aundy\.DevShell v0\.4\.0'
        $output | Should -Match '(?m)^\s*Workspace\s*$'
        $output | Should -Match '(?m)^\s*Get-Workspace\s*$'
        $output | Should -Match '(?m)^\s*Testing\s*$'
    }

    It 'shows a category with command summaries' {
        $output = Show-DevShell workspace | Out-String
        $output | Should -Match '(?m)^\s*Workspace\s*$'
        $output | Should -Match 'Get-Workspace'
        $output | Should -Match 'Returns the current developer workspace\.'
        $output | Should -Not -Match 'Clear-GitWorkspace'
    }

    It 'shows navigation for an exact command' {
        $output = Show-DevShell Get-Workspace | Out-String
        $output | Should -Match '(?m)^\s*Purpose\s*$'
        $output | Should -Match '(?m)^\s*Related\s*$'
        $output | Should -Not -Match '\bGet-Help\b'
    }

    It 'searches names summaries categories and related commands case insensitively' {
        $output = Show-DevShell cLaUdE | Out-String
        $output | Should -Match 'Invoke-ClaudeLocal'
        $output | Should -Match 'Invoke-ClaudeApi'
    }

    It 'handles an unknown category or command gracefully' {
        $warnings = @()
        $output = Show-DevShell does-not-exist -WarningVariable warnings | Out-String
        $output | Should -BeNullOrEmpty
        $warnings | Out-String | Should -Match 'No DevShell category or command matches'
    }

    It 'provides the dev alias' {
        (Get-Alias dev).Definition | Should -Be 'Show-DevShell'
    }

    It 'does not use PowerShell discovery APIs to build help output' {
        $showPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Public/Show-DevShell.ps1'
        $getterPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Public/Get-DevShellCommands.ps1'
        $registryPath = Join-Path $PSScriptRoot '../src/Aundy.DevShell/Private/Get-DevShellCommandRegistry.ps1'
        $implementation = Get-Content -LiteralPath @($showPath, $getterPath, $registryPath) -Raw

        $implementation | Should -Not -Match '\bGet-Command\b'
        $implementation | Should -Not -Match '\bGet-Module\b'
        $implementation | Should -Not -Match '\bGet-Help\b'
    }

    It 'never displays unregistered PowerShell or third-party commands' {
        $output = Show-DevShell | Out-String
        $registeredPublicNames = @(Get-DevShellCommands |
            Where-Object Visibility -eq 'Public' |
            Select-Object -ExpandProperty Name)

        foreach ($externalCommand in @('Get-Command', 'Invoke-Pester', 'oh-my-posh', 'Import-Module')) {
            $registeredPublicNames | Should -Not -Contain $externalCommand
            $output | Should -Not -Match "(?m)^\s*$([regex]::Escape($externalCommand))\s*$"
        }
    }

    It 'only displays public registered commands as related navigation' {
        $output = Show-DevShell Get-DevContext | Out-String
        $output | Should -Not -Match '(?m)^\s*Get-MachineContext\s*$'
        $output | Should -Match '(?m)^\s*Show-DevContext\s*$'
    }
}
